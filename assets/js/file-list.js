"use strict";

import Upload from "./upload";
import File from "./file"

class FileList {
    constructor(element) {
        this.uploading = new Map();
        this.uploaded = new Map();
        this.files = new Map();
        this.element = element;
    }

    addUpload(id, name) {
        const upload = new Upload(id, name);
        this.uploading.set(id, upload);
        this.element.appendChild(upload.element);
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
        this.element.appendChild(file.element);
        file.render();
    }
}


export default FileList;
