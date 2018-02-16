"use strict";

import asyncButton from "./async-button-view";

export default function(room) {
    return {
        name: "upload",
        template: "#upload-template",
        props: ["role", "index", "id"],
        data() {
            return room.fileList.searchUploads(this.id, (upload, i) => {
                return upload;
            });
        },
        computed: {
            progress() {
                return Math.round((this.uploaded / this.file.size) * 100);
            },
            domId() {
                return "upload-" + this.id;
            },
            isOdd() {
                return this.index % 2;
            },
            isEven() {
                return (this.index + 1) % 2;
            }
        },
        components: {
            asyncButton: asyncButton
        }
    };
};
