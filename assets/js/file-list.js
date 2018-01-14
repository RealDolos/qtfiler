"use strict";

const Upload  = require("./upload");
const File  = require ("./file");

class FileList {
    constructor(element) {
        this.uploading = new Map();
        this.uploaded = new Map();
        this.files = new Map();
        this.element = element;
        this.odd = false;
        this.role = "user";
    }

    addUpload(id, name) {
        const upload = new Upload(id, name);
        this.uploading.set(id, upload);
        this.element.prepend(upload.element);
        upload.initialRender();
        upload.render();
    }

    progressUpload(id, uploaded, total) {
        const upload = this.uploading.get(id);
        upload.uploaded = uploaded;
        upload.total = total;
        upload.render();
    }

    completeUpload(id) {
        const upload = this.uploading.get(id);
        upload.kys();
        this.uploading.delete(id);
    }

    addFile(data) {
        const file = File.create(data);
        this.files.set(file.uuid, file);
        this.element.prepend(file.element);
        file.initialRender(this.odd);
        file.render();
        this.odd = !this.odd;
        this.render();
    }

    render() {
        const mods = document.getElementsByClassName("mod");
        for (const mod of mods) {
            if (!(this.role == "mod") || (this.role == "admin")) {
                mod.classList.add("hidden");
            } else {
                mod.classList.remove("hidden");
            }
        }
    }
}


module.exports = FileList;
