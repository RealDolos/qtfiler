"use strict";

class File {
    static create(data) {
        const file = new File();
        return Object.assign(file, data);
    }

    constructor() {
        this.element = document.createElement("div");
        this.link = document.createElement("a");
        this.element.appendChild(this.link);
    }

    render() {
        this.element.className = "file-container";
        this.link.className = "file-link";
        this.link.setAttribute("data-hash-sha1", this.hash);
        this.link.innerText = this.filename;
        this.link.href = `/get/${this.uuid}/${this.filename}`;
        this.link.target = "_blank";
        const uploader_badge = document.createElement("span");
        uploader_badge.innerText = this.uploader;
        uploader_badge.className = "file-uploader";
        this.element.appendChild(uploader_badge);
    }

    kys() {
        this.element.remove();
    }
}

export default File;
