"use strict";

export default class File {
    static create(data) {
        const file = new File();
        return Object.assign(file, data);
    }

    constructor() {
        this.markedForDeletion = false;
    }
}
