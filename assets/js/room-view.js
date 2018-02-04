"use strict";

const socket = require("./socket");
const Room = require("./room");
const Vue = require("vue/dist/vue.common.js");
const fileListView = require("./file-list-view");
const presenceView = require("./presence-view");
const room = new Room(socket);

// A room with a vue
module.exports = new Vue({
    name: "room",
    data: room,
    el: "#room",
    components: {
        fileList: fileListView(room),
        presence: presenceView(room)
    },
    mounted() {
        room.initialiseUploader();
    },
    methods: {
        async deleteFiles() {
            const files = room.fileList.getDeletedFiles();
            await room.deleteFiles(files);
        }
    },
    computed: {
        mod() {
            return this.role == "mod" || this.role == "admin";
        }
    }
});
