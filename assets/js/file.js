"use strict";

class File {
    static create(data) {
        const file = new File();
        return Object.assign(file, data);
    }

    constructor() {
        this.markedForDeletion = false;
    }

    async delete() {
        const url = "/api/mod/delete" + "?uuid=" + this.uuid;
        const result = await fetch(url, {
            method: "POST",
            credentials: "include"
        });
        const data = await result.json();
        return data;
    }
}

module.exports = File;
