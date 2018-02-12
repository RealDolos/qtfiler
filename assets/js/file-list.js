"use strict";

const Upload  = require("./upload");
const File  = require ("./file");

class FileList {
    constructor(room_id) {
        this.uploads = [];
        this.files = [];
        this.status = 0;
        this.room_id = room_id;
    }

    async wakeUploader() {
        if (this.status) {
            return;
        }

        this.status += 1;

        try {
            await this.performUploads();
        } finally {
            // todo: catch
            this.status -= 1;
        }
    }

    async performUploads() {
        while (this.uploads.length) {
            await this.upload(this.uploads[0]);
            this.uploads.shift();
        }
    }

    upload(upload) {
        return new Promise((resolve, reject) => {
            const req = new XMLHttpRequest();
            var query = "room_id=" + this.room_id + "&filename=" + upload.file.name;

            if (upload.file.type) {
                query += "&content_type=" + upload.file.type;
            }

            req.open("POST", "/api/upload?" + query, true);
            req.setRequestHeader("Content-Type", "application/octet-stream");

            req.upload.addEventListener("progress", (ev) => {
                if (ev.lengthComputable) {
                    upload.uploaded = ev.loaded;
                }
            });

            req.addEventListener("load", (ev) => {
                resolve(req.response);
            });

            req.addEventListener("error", (ev) => {
                reject(req.response);
            });

            req.addEventListener("abort", (ev) => {
                resolve("aborted xhr");
            });

            req.send(upload.file);
        });
    }

    async addUpload(id, name) {
        const upload = new Upload(id, name);
        this.uploads.push(upload);
        await this.wakeUploader();
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

    setFileDeletionFailed(uuids) {
        for (let file of this.files.reverse()) {
            if (uuids[uuids.length - 1] == file.uuid) {
                file.deleteStatus = "failed";
                uuids.pop();
            }
        }
    }

    setFileDeletionResults(uuids, results) {
        for (let file of this.files.reverse()) {
            if (uuids[uuids.length - 1] == file.uuid) {
                if (results[results.length - 1] == "ok") {
                    file.deleteStatus = "succeeded";
                } else {
                    file.deleteStatus = "failed";
                }
                results.pop();
                uuids.pop();
            }
        }
    }

    getDeletedFiles() {
        const result = [];
        for (let file of this.files) {
            if (file.marked) {
                file.deleteStatus = "waiting";
                result.push(file.uuid);
            }
        }
        return result;
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
