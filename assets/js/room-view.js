"use strict";

import socket from "./socket";
import Room from "./room";
import _ from "lodash";
import Vue from "vue/dist/vue.common.js";
import memoize from "./memoize";
import fileListView from "./file-list-view";
import presenceView from "./presence-view";
import settingsView from "./settings-view";
const room = new Room(socket);
room.initialise();

const MOD_ROLES = Object.freeze(new Set(["mod", "admin"]));
const FILTER_DEBOUNCE = 100;

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

// A room with a vue
export default new Vue({
  name: "room",
  data: room,
  el: "#room",
  components: {
    fileList: fileListView(room),
    presence: presenceView(room),
    settings: settingsView
  },
  mounted() {
    room.initialiseUploader();
  },
  methods: {
    async deleteFiles() {
      const files = room.fileList.getDeletedFiles();
      await room.deleteFiles(files);
    },
    togglePresence() {
      this.presenceSize = (this.presenceSize + 1) % 4;
    },
    saveSettings(settings) {
      return this.$data.push("settings", settings);
    },
    setSettingsCallback(cb) {
      return this.$data.channel.on("settings", cb);
    },
    setUserSettings(settings) {
      this.settings = settings;
    },
    debounceFilter: _.debounce(function (e) {
      this.filter = e.target.value;
      this.filters = this.filter.split(" ").map(toFilter).filter(e => e);
      if (!this.filters.length) {
        this.filters = null;
        this.$refs.filelist.$children.forEach(f => {
          f.filtered = true;
        });
      }
      else {
        this.$refs.filelist.$children.forEach(f => {
          f.filtered = this.filters.every(e => e(f));
        });
      }
    }, FILTER_DEBOUNCE),
  },
  computed: {
    mod() {
      return this.owner || MOD_ROLES.has(this.role);
    },
    presenceBig() {
      return this.presenceSize === 3;
    },
    presenceMedium() {
      return this.presenceSize === 2;
    },
    presenceSmall() {
      return this.presenceSize === 1;
    },
    presenceHidden() {
      return this.presenceSize === 0;
    }
  }
});
