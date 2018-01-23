"use strict";

module.exports = (room) => {
    return {
        data() {
            const x = room.fileList.searchFiles(this.uuid, (file, i) => {
                return file;
            });
            return x;
        },
        name: "file",
        template: "#file-template",
        props: ["role", "uuid", "index"],
        computed: {
            domId() {
                return "file-" + this.uuid;
            },
            link() {
                return `/get/${this.uuid}/${this.filename}`;
            },
            mod() {
                return this.role == "mod" || this.role == "admin";
            },
            isOdd() {
                return this.index % 2;
            },
            isEven() {
                return (this.index + 1) % 2;
            },
            formattedExpirationDate() {
                return (new Date(this.expiration_date)).toLocaleString();
            }
        }
    };
};
