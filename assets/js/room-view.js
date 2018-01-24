"use strict";

const socket = require("./socket");
const Room = require("./room");
const Vue = require("vue/dist/vue.common.js");
const fileListView = require("./file-list-view");
const room = new Room(socket);

// A room with a vue
module.exports = new Vue({
    name: "room",
    data: room,
    el: "#room",
    components: {
        fileList: fileListView(room)
    },
    methods: {
        async deleteFiles() {
            try {
                const files = room.fileList.getDeletedFiles();
                const results = await room.push("delete", {files: files})
                // todo: handle result
                console.log("files deleted: " + results.results)
            } catch (e) {
                console.log("failed to delete files: " + e)
            }
        }
    },
    computed: {
        mod() {
            return this.role == "mod" || this.role == "admin";
        }
    }
});
