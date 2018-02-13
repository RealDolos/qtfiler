"use strict";

export default function(room) {
    return {
        data() {
            const x = room.fileList.searchFiles(this.uuid, (file, i) => {
                return file;
            });
            return x;
        },
        name: "file",
        template: "#file-template",
        props: ["role", "uuid", "index", "filesLength"],
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
                return (this.index + this.filesLength) % 2;
            },
            isEven() {
                return (this.index + this.filesLength + 1) % 2;
            },
            formattedExpirationDate() {
                return (new Date(this.expiration_date)).toLocaleString();
            },
            shrunken_ip() {
                return this.ip_address.substring(0, 22);
            }
        },
        methods: {
            async deleteMe() {
                this.deleteStatus = "waiting";
                const files = [this.uuid];
                await room.deleteFiles(files);
            },
            async banMe() {
                console.log("banned ;^)");
            }
        }
    };
};
