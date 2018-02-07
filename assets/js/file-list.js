"use strict";

const Upload  = require("./upload");
const File  = require ("./file");

class FileList {
    constructor(room_id) {
        this.uploads = [];
        this.files = [];
        this.status = "ready";
        this.room_id = room_id;
    }

    checkForUploads() {
        if (this.status == "ready" && this.uploads.length) {
            this.startUpload(this.uploads[0]);
        }
    }

    startUpload(upload) {
        this.status = "uploading";
        const req = new XMLHttpRequest();
        var query = "room_id=" + this.room_id + "&filename=" + upload.file.name;
        if (upload.file.type) {
            query += "&content_type=" + upload.file.type;
        }
        req.open("POST", "/api/upload?" + query, true);
        req.setRequestHeader("Content-Type", "application/octet-stream");
        req.upload.onprogress = (ev) => {
            if (ev.lengthComputable) {
                upload.uploaded = ev.loaded;
            }
        };
        req.onload = (ev) => {
            this.completeUpload(upload.id);
            this.status = "ready";
            this.checkForUploads();
        };
        req.send(upload.file);
    }

    addUpload(id, name) {
        const upload = new Upload(id, name);
        this.uploads.push(upload);
        this.checkForUploads();
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

    getDeletedFiles() {
        const result = [];
        for (let file of this.files) {
            if (file.markedForDeletion) {
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
