"use strict";

import file from "./file-view";
import upload from "./upload-view";
import lodash from "lodash";

const DISPLAY_THROTTLE = 125;

function ok(actual, expected) {
  return actual.toUpperCase().includes(expected);
}

function not(actual, expected) {
  return !actual.toUpperCase().includes(expected);
}

function toFilter(e) {
  e = e.toUpperCase().trim();
  if (!e) {
    return null;
  }

  const pred = e[0] !== "-";
  const check = pred ? ok : not;
  if (!pred) {
    e = e.slice(1); // chop off that leading "-"
  }

  let [type, ...rest] = e.split(":");
  if (!rest.length) {
    rest = type;
    type = "FILE";
  }
  else {
    rest = rest.join(":");
  }

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
}

export default function(room) {
  return {
    name: "fileList",
    template: "#file-list-template",
    props: ["role", "filter", "owner", "settings"],
    data() {
      return room.fileList;
    },
    components: {
      file: file(room),
      upload: upload(room)
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

      filteredFiles() {
        const filters = this.filter.split(" ").map(toFilter).filter(e => e);
        return filters.length ?
          this.files.filter(f => filters.every(fn => fn(f))) :
          this.files.slice();
      },
      filesLength() {
        return this.files.length;
      },
      filteredFilesLength() {
        return this.filteredFiles.length;
      },
    },
    methods: {
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
        return await this.$data.wakeUploader();
      },
      async pause(id) {
        return await this.$data.pause(id);
      },
      displayInfo: lodash.debounce(function(uuid) {
        this.info = uuid;
      }, DISPLAY_THROTTLE)
    }
  };
}
