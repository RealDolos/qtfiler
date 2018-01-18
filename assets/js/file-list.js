"use strict";

const Upload  = require("./upload");
const File  = require ("./file");

class FileList {
    constructor(element) {
        this.uploads = [];
        this.files = [];
    }

    addUpload(id, name) {
        const upload = new Upload(id, name);
        this.uploads.push(upload);
    }

    static search(idKey, items, id, cont) {
        for (let i = 0; i < items.length; i++) {
            if (items[i][idKey] == id) {
                return cont(items[i], i);
            }
        }
        return null;
    }

    searchUploads(id, cont) {
        return FileList.search("id", this.uploads, id, cont);
    }

    searchFiles(id, cont) {
        return FileList.search("uuid", this.files, id, cont);
    }

    async deleteFiles() {
        for (let i = 0; i < this.files.length;) {
            if (this.files[i].markedForDeletion) {
                const result = await this.files[i].delete();
                if (result.success) {
                    this.files.splice(i, 1);
                } else {
                    console.log("failed to delete file: " + this.files[i].uuid + " with result: " + result);
                    i++;
                }
            } else {
                i++;
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
