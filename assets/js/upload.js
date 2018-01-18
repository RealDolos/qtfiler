"use strict";

class Upload {
    constructor(id, name) {
        this.id = id;
        this.name = name;
        this.uploaded = 0;
        this.total = 1;
    }
};

module.exports = Upload;
