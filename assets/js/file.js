"use strict";

class File {
    static create(data) {
        const file = new File();
        return Object.assign(file, data);
    }

    constructor() {
        this.marked = false;
        this.deleteStatus = "ready";
        this.banStatus = "ready";
    }
}

module.exports = File;
