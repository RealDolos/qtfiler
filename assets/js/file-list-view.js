"use strict";
/* globals XMLHttpRequest */

import file from "./file-view";
import memoize from "./memoize";
import Upload from "./upload";
import upload from "./upload-view";
import lodash from "lodash";

const DISPLAY_THROTTLE = 125;
const FILTER_THROTTLE = 250;

let sortId = 0;

function toFile(data) {
  return Object.assign(data, {
    sortId: ++sortId,
    marked: false,
    deleteStatus: "ready",
    previews: []
  });
}

function ok(actual, expected) {
  return actual.toUpperCase().includes(expected);
}

function not(actual, expected) {
  return !actual.toUpperCase().includes(expected);
}

const createFilter = memoize(function createFilter(pred, type, rest) {
  if (!rest) {
    return null;
  }
  const check = pred ? ok : not;
  switch (type) {
  case "USER":
    return f => check(f.uploader, rest);

  case "FILE":
    // fall through

  case "NAME":
    // fall through

  case "FILENAME":
    return f => check(f.filename, rest);

  default:
    /* unknown tag, rejoin and match against name */
    rest = `${type}:${rest}`;
    return f => check(f.filename, rest);
  }
}, 1000);

function toFilter(e) {
  e = e.toUpperCase().trim();
  if (!e) {
    return null;
  }

  const pred = e[0] !== "-";
  if (!pred) {
    e = e.slice(1); // chop off that leading "-"
  }

  const sep = e.indexOf(":");
  const type = sep === -1 ? "FILE" : e.slice(0, sep);
  const rest = sep === -1 ? e : e.slice(sep + 1);
  return createFilter(pred, type, rest);
}

function bySortId(a, b) {
  return b.sortId - a.sortId;
}

export default function(room) {
  return {
    name: "fileList",

    template: "#file-list-template",

    props: ["role", "filter", "owner", "settings"],

    data() {
      room.fileList = this;
      this.applyFilter();
      return {
        ids: new Map(),
        uploads: [],
        files: [],
        status: 0,
        room_id: room.room_id,
        current: null,
        currentID: "",
        info: "",
        mouse: { x: 0, y: 0 },
      };
    },

    components: {
      file: file(room),
      upload: upload(room)
    },

    watch: {
      filter: lodash.debounce(function() {
        this.applyFilter();
      }, FILTER_THROTTLE)
    },

    computed: {
      hovery() {
        for (const setting of this.settings) {
          if (setting.key === "hover") {
            return setting.value;
          }
        }
        return false;
      },
    },

    methods: {
      applyFilter() {
        const filters = this.filter.split(" ").map(toFilter).filter(e => e);
        if (filters.length) {
          this.filters = filters;
          this.isFiltered = this.isFilteredFilters;
        }
        else {
          this.filters = null;
          this.isFiltered = this.isFilteredTrue;
        }
        this.$nextTick(() => {
          const children = this.$children.slice();
          children.sort(bySortId);
          children.forEach(c => {
            c.applyFilter && c.applyFilter();
          });
        });
      },

      isFilteredTrue() {
        return true;
      },

      isFilteredFilters(file) {
        return this.filters.every(fn => fn(file));
      },

      getFileByUUID(uuid) {
        return this.ids.get(uuid);
      },

      setFileDeletionFailed(uuids) {
        uuids = new Set(uuids);
        this.files.forEach(f => {
          if (!uuids.has(f.uuid)) {
            return;
          }
          f.deletedStatus = "failed";
        });
      },

      setFileDeletionResults(uuids, results) {
        uuids = new Map(uuids.map((u, i) => [u, results[i]]));
        this.files.forEach(f => {
          const res = uuids.get(f.uuid);
          if (!res) {
            return;
          }
          f.deletedStatus = res;
        });
      },

      getDeletedFiles() {
        const result = [];
        for (const file of this.files) {
          if (file.marked) {
            file.deleteStatus = "waiting";
            result.push(file.uuid);
          }
        }
        return result;
      },

      progressUpload(id, uploaded, total) {
        const upload = this.uploads.find(u => u.id === id);
        if (!upload) {
          return;
        }
        upload.uploaded = uploaded;
        upload.total = total;
      },

      completeUpload(id) {
        const upload = this.uploads.findIndex(u => u.id === id);
        if (upload < 0) {
          return;
        }
        this.uploads.splice(upload, 1);
      },

      removeFile(uuid) {
        const idx = this.files.findIndex(file => file.uuid === uuid);
        if (idx < 0) {
          return;
        }
        this.ids.delete(uuid);
        this.files.splice(idx, 1);
      },

      addFile(data) {
        this.files.unshift(toFile(data));
        this.ids.set(data.uuid, data);
      },

      addNewFiles(data) {
        // we need to call toFile in reverse for sortIds to be generated
        // properly.
        // Then we need to undo by another reverse
        this.files = data.reverse().map(data => {
          this.ids.set(data.uuid, data);
          return toFile(data);
        }).reverse();
      },

      mouseMove(e) {
        if (!this.hovery) {
          return;
        }
        for (let {target} = e; target !== e.currentTarget;
          target = target.parentElement) {
          if (!target.classList.contains("file-container")) {
            continue;
          }
          const thumb = target.firstChild.nextElementSibling;

          if (!thumb) {
            break;
          }
          const rect = e.currentTarget.getBoundingClientRect();

          thumb.style.setProperty(
            "transform",
            `translate(${e.clientX + 1 - rect.left}px, ${e.clientY + 1 - rect.top}px)`
          );
        }
      },

      async wake() {
        return await this.wakeUploader();
      },

      displayInfo: lodash.debounce(function(uuid) {
        this.info = uuid;
      }, DISPLAY_THROTTLE),

      sleep(time) {
        return new Promise(resolve => setTimeout(resolve, time));
      },

      async wakeUploader() {
        if (this.status) {
          return {
            success: true
          };
        }

        this.status += 1;

        try {
          await this.performUploads();
        }
        finally {
          // todo: catch
          this.status -= 1;
        }

        return {
          success: true
        };
      },

      pause(id) {
        if (this.currentID === id && this.current !== null) {
          this.current.abort();
        }
      },

      getNextUpload() {
        for (const upload of this.uploads) {
          if (!upload.paused) {
            return upload;
          }
        }
        return null;
      },

      async performUploads() {
        let upload = null;
        while ((upload = this.getNextUpload()) !== null) {
          try {
            const result = await this.upload(upload);
            this.current = null;

            if (result.done) {
              this.uploads.shift();
            }
            else if ("offset" in result) {
              upload.uploaded = result.offset;
            }
          }
          catch (e) {
            console.error(e);
            if (!e.aborted) {
              await this.sleep((2 ** upload.attempt) * 1000);
              upload.attempt += 1;
            }
            else {
              // XXX display error
              this.completeUpload(upload.id);
            }
          }
        }
        this.current = null;
      },

      upload(upload) {
        const offset = upload.uploaded;

        let query =
            `room_id=${encodeURIComponent(this.$data.room_id)
            }&filename=${encodeURIComponent(upload.file.name)
            }&upload_id=${encodeURIComponent(upload.id)
            }&offset=${encodeURIComponent(offset)
            }&size=${encodeURIComponent(upload.file.size)}`;

        if (upload.file.type) {
          query += `&content_type=${encodeURIComponent(upload.file.type)}`;
        }

        return new Promise((resolve, reject) => {
          const req = new XMLHttpRequest();
          this.current = req;
          this.currentID = upload.id;
          req.open("POST", `/api/upload?${query}`, true);
          req.setRequestHeader("Content-Type", "application/octet-stream");

          const progress = ev => {
            if (ev.lengthComputable) {
              upload.uploaded = ev.loaded + offset;
            }
          };

          req.upload.addEventListener("progress", progress);

          req.addEventListener("load", () => {
            req.upload.removeEventListener("progress", progress);
            const res = JSON.parse(req.response);
            if (!res.success) {
              reject(Object.assign(res, {
                done: false,
                success: false,
                aborted: res.preventRetry
              }));
            }
            else {
              resolve(res);
            }
          });

          req.addEventListener("error", () => {
            req.upload.removeEventListener("progress", progress);
            reject({
              done: false,
              success: false,
              aborted: false
            });
          });

          req.addEventListener("abort", () => {
            req.upload.removeEventListener("progress", progress);
            reject({
              success: false,
              aborted: true,
              done: false
            });
          });

          if (upload.paused) {
            reject({
              success: false,
              done: false,
              aborted: true
            });
          }
          else {
            req.send(upload.file.slice(offset));
          }
        });
      },

      async addUpload(name) {
        const upload = new Upload(name);
        this.uploads.push(upload);
        await this.wakeUploader();
      },

    },
  };
}
