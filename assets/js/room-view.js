"use strict";

import socket from "./socket";
import Room from "./room";
import Vue from "vue/dist/vue.common.js";
import fileListView from "./file-list-view";
import presenceView from "./presence-view";
const room = new Room(socket);

// A room with a vue
export default new Vue({
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
