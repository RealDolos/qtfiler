"use strict";

import Upload from "./upload";
import File from "./file";

class FileList {
    constructor(element) {
        this.uploading = new Map();
        this.uploaded = new Map();
        this.files = new Map();
        this.element = element;
        this.odd = false;
    }

    addUpload(id, name) {
        const upload = new Upload(id, name);
        this.uploading.set(id, upload);
        this.element.prepend(upload.element);
        upload.initialRender(this.odd);
        upload.render();
        this.odd = !this.odd;
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
        this.odd = !this.odd;
    }

    addFile(data) {
        const file = File.create(data);
        this.files.set(file.uuid, file);
        this.element.prepend(file.element);
        file.initialRender(this.odd);
        file.render();
        this.odd = !this.odd;
    }
}


export default FileList;
