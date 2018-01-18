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
        // this loop is retarded to deal with a race condition where the await finishes
        // after the file entry has been spliced from the filelist, thus shifting all the
        // files down, which means we need to check the current index again
        for (let i = 0; i < this.files.length;) {
            if (this.files[i].markedForDeletion) {
                this.files[i].markedForDeletion = false;
                const result = await this.files[i].delete();
                if (result.success) {
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

    removeFile(uuid) {
        this.searchFiles(uuid, (file, i) => {
            this.files.splice(i, 1);
        });
    }

    addFile(data) {
        const file = File.create(data);
        this.files.unshift(file);
    }
}


module.exports = FileList;
