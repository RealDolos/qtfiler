"use strict";

class File {
    static create(data) {
        const file = new File();
        return Object.assign(file, data);
    }

    constructor() {
        this.markedForDeletion = false;
    }
}

module.exports = File;
