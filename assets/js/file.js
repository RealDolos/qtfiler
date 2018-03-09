"use strict";

export default class File {
    static create(data) {
        const file = Object.assign(new File(), data);
        return file;
    }

    constructor() {
        this.marked = false;
        this.deleteStatus = "ready";
        this.banStatus = "ready";
        this.metadata = {
            data: {}
        };
        this.previews = [];
    }
}
