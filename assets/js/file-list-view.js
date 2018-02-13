"use strict";

import file from "./file-view";
import upload from "./upload-view";

export default function(room) {
    return {
        name: "fileList",
        template: "#file-list-template",
        props: ["role", "filter"],
        data() {
            return room.fileList;
        },
        components: {
            file: file(room),
            upload: upload(room)
        },
        computed: {
            filteredFiles() {
                return this.files.filter((f) => {
                    return f.filename.toUpperCase().search(this.filter.toUpperCase()) >= 0;
                });
            },
            filesLength() {
                return this.files.length;
            },
            filteredFilesLength() {
                return this.filteredFiles.length;
            }
        }
    };
};
