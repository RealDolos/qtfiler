"use strict";

class Upload {
    constructor(id, name) {
        this.id = id;
        this.name = name;
        this.uploaded = 0;
        this.total = 1;
        this.element = document.createElement("div");
    }

    initialRender() {
        this.element.className = "file-container";
    }

    render() {
        this.element.innerText = this.name + " " +
            Math.round((this.uploaded / this.total) * 100) + "%";
    }

    kys() {
        this.element.remove();
    }
};

module.exports = Upload;
