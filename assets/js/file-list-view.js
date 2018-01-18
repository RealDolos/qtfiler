"use strict";

const file = require("./file-view");
const upload = require("./upload-view");

module.exports = (room) => {
    return {
        name: "fileList",
        template: "#file-list-template",
        props: ["role"],
        data() {
            return room.fileList;
        },
        components: {
            file: file(room),
            upload: upload(room)
        }
    };
};
