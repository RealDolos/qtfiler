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
        deleteFiles() {
            return room.fileList.deleteFiles();
        }
    },
    computed: {
        mod() {
            return this.role == "mod" || this.role == "admin";
        }
    }
});
