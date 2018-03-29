"use strict";

import socket from "./socket";
import Room from "./room";
import Vue from "vue/dist/vue.common.js";
import fileListView from "./file-list-view";
import presenceView from "./presence-view";
import settingsView from "./settings-view";
const room = new Room(socket);
room.initialise();
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
    }
  },
  computed: {
    mod() {
      return this.role == "mod" || this.role == "admin" || this.owner;
    },
    presenceBig() {
      return this.presenceSize == 3;
    },
    presenceMedium() {
      return this.presenceSize == 2;
    },
    presenceSmall() {
      return this.presenceSize == 1;
    },
    presenceHidden() {
      return this.presenceSize == 0;
    }
  }
});
