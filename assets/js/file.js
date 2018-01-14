"use strict";

class File {
    static create(data) {
        const file = new File();
        return Object.assign(file, data);
    }

    constructor() {
        this.element = document.createElement("div");
        this.link = document.createElement("a");
        this.uploader_badge = document.createElement("span");
        this.element.appendChild(this.link);
        this.element.appendChild(this.uploader_badge);
        this.deleteButton = document.createElement("div");
        this.element.appendChild(this.deleteButton);
        const self = this;
        this.deleteButton.onclick = function(ev) {
            self.delete();
        };
    }

    async delete() {
        const url = "/api/mod/delete" + "?uuid=" + this.uuid;
        const result = await fetch(url, {
            method: "POST",
            credentials: "include"
        });
        const data = await result.json();
        console.log(data);
        this.kys();
    }

    initialRender(odd) {
        this.element.className = "file-container " + (odd ? "file-odd" : "");
        this.link.className = "file-link";
        this.link.setAttribute("data-hash-sha1", this.hash);
        this.link.innerText = this.filename;
        this.link.href = `/get/${this.uuid}/${this.filename}`;
        this.link.target = "_blank";
        this.uploader_badge.innerText = this.uploader;
        this.uploader_badge.className = "file-uploader";
        this.deleteButton.innerText = "delete";
        this.deleteButton.className = "delete mod button";
    }

    render() {
    }

    kys() {
        this.element.remove();
    }
}

module.exports = File;
