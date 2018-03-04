"use strict";

import asyncButton from "./async-button-view";

export default function(room) {
    return {
        name: "upload",
        template: "#upload-template",
        props: ["role", "index", "id", "wake", "pause"],
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
            },
            running() {
                return !this.paused;
            }
        },
        components: {
            asyncButton: asyncButton
        },
        methods: {
            async toggle() {
                this.paused = !this.paused;
                if (this.paused) {
                    this.pause(this.id);
                }
                return await this.wake();
            }
        }
    };
};
