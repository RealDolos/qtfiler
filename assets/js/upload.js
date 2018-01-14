"use strict";

class Upload {
    constructor(id, name) {
        this.id = id;
        this.name = name;
        this.uploaded = 0;
        this.total = 0;
        this.element = document.createElement("div");
    }

    render() {
        this.element.innerText = this.name + " " +
            Math.round((this.uploaded / this.total) * 100) + "%";
    }

    kys() {
        this.element.remove();
    }
};

export default Upload;
