"use strict";

export default class Upload {
    constructor(file) {
        const array = new Uint8Array(16);
        window.crypto.getRandomValues(array);
        let id = "";

        for (let x of array) {
            id += String.fromCodePoint(x);
        }

        this.id = btoa(id);
        this.file = file;
        this.uploaded = 0;
        this.attempt = 0;
        this.paused = false;
    }
};
