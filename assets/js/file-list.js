"use strict";
/* globals XMLHttpRequest */

import Upload from "./upload";

function createFileData(data) {
  return Object.assign(data, {
    marked: false,
    filtered: true,
    deleteStatus: "ready",
    banStatus: "ready",
    previews: [],
  });
}

export default class FileList {
  constructor(room_id) {
    this.uploads = [];
    this.files = [];
    this.uuids = new Map();
    this.status = 0;
    this.room_id = room_id;
    this.current = null;
    this.currentID = "";
    this.info = "";
    this.mouse = { x: 0, y: 0 };
  }

  sleep(time) {
    return new Promise(resolve => setTimeout(resolve, time));
  }

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
  }

  pause(id) {
    if (this.currentID === id && this.current !== null) {
      this.current.abort();
    }
  }

  getNextUpload() {
    for (const upload of this.uploads) {
      if (upload.paused) {
        continue;
      }
      return upload;
    }
    return null;
  }

  async performUploads() {
    let upload = null;
    while ((upload = this.getNextUpload()) !== null) {
      try {
        const result = await this.upload(upload);
        this.current = null;

        if (result.done) {
          this.completeUpload(upload.id);
        }
        else if ("offset" in result) {
          upload.uploaded = result.offset;
        }
      }
      catch (e) {
        if (!e.aborted) {
          await this.sleep((2 ** upload.attempt) * 1000);
          upload.attempt += 1;
        }
      }
    }
    this.current = null;
  }

  upload(upload) {
    const offset = upload.uploaded;

    let query =
            `room_id=${encodeURIComponent(this.room_id)
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
        resolve(JSON.parse(req.response));
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
  }

  async addUpload(name) {
    const upload = new Upload(name);
    this.uploads.push(upload);
    await this.wakeUploader();
  }

  searchUploads(id, cont) {
    const upload = this.uploads.find(e => e.id === id) || null;
    return cont ? cont(upload, 0) : upload;
  }

  searchFiles(id, cont) {
    const file = this._uuids.get(id) || null;
    return cont ? cont(file, 0) : file;
  }

  setFileDeletionFailed(uuids) {
    for (const file of this.files.reverse()) {
      if (uuids[uuids.length - 1] === file.uuid) {
        file.deleteStatus = "failed";
        uuids.pop();
      }
    }
  }

  setFileDeletionResults(uuids_original, results_original) {
    const uuids = uuids_original.slice(0);
    const results = results_original.slice(0);
    for (const file of this.files.reverse()) {
      if (uuids[uuids.length - 1] === file.uuid) {
        if (results[results.length - 1] === "ok") {
          file.deleteStatus = "succeeded";
        }
        else {
          file.deleteStatus = "failed";
        }
        results.pop();
        uuids.pop();
      }
    }
  }

  getDeletedFiles() {
    const result = [];
    for (const file of this.files) {
      if (file.marked) {
        file.deleteStatus = "waiting";
        result.push(file.uuid);
      }
    }
    return result;
  }

  progressUpload(id, uploaded, total) {
    const u = this.uploads.find(e => e.id === id);
    if (!u) {
      return;
    }
    u.uploaded = uploaded;
    u.total = total;
  }

  completeUpload(id) {
    const idx = this.uploads.findIndex(e => e.id === id);
    if (idx < 0) {
      return;
    }
    this.uploads.splice(idx, 1);
  }

  removeFile(uuid) {
    const file = this._uuids.get(uuid);
    if (!file) {
      return;
    }
    const idx = this.files.indexOf(file);
    if (idx < 0) {
      return;
    }
    this._uuids.delete(uuid);
    this.files.splice(idx, 1);
  }

  addFile(data) {
    createFileData(data);
    this.files.unshift(data);
    this._uuids.set(data.uuid, data);
  }

  addNewFiles(data) {
    this._uuids = new Map();
    data.forEach(data => {
      createFileData(data);
      this._uuids.set(data.uuid, data);
    });
    this.files = data;
  }
}
