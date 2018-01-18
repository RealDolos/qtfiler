"use strict";

const Upload  = require("./upload");
const File  = require ("./file");

class FileList {
    constructor(element) {
        this.uploads = [];
        this.files = [];
        this.role = "user";
    }

    addUpload(id, name) {
        const upload = new Upload(id, name);
        this.uploads.push(upload);
    }

    searchUploads(id, cont) {
        for (let i = 0; i < this.uploads.length; i++) {
            if (this.uploads[i].id == id) {
                cont(this.uploads[i], i);
            }
        }
    }

    progressUpload(id, uploaded, total) {
        this.searchUploads(id, (upload, i) => {
            upload.uploaded = uploaded;
            upload.total = total;
        });
    }

    completeUpload(id) {
        this.searchUploads(id, (upload, i) => {
            this.uploads.splice(i, 1);
        });
    }

    addFile(data) {
        const file = File.create(data);
        this.files.unshift(file);
    }
}


module.exports = FileList;
