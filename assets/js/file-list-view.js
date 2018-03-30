"use strict";

import file from "./file-view";
import upload from "./upload-view";
import lodash from "lodash";

const DISPLAY_THROTTLE = 125;

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

      filesLength() {
        return this.files.length;
      },

      styleVars() {
        return {
          "--x": `${this.mouse.x}px`,
          "--y": `${this.mouse.y}px`,
        };
      }
    },
    methods: {
      mouseMove(e) {
        this.mouse.x = e.pageX + 1;
        this.mouse.y = e.pageY + 1;
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
