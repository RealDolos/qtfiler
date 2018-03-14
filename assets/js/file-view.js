"use strict";

import asyncButton from "./async-button-view";

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
        props: ["role", "uuid", "index", "filesLength", "owner", "displayInfo", "displayInfoHere"],
        computed: {
            tagList() {
                if (this.metadata != null) {
                    const {data: {format: {tags: tags = {}} = {}} = {}} = this.metadata;
                    const list = [];
                    for (let key in tags) {
                        list.push({
                            key: key,
                            value: tags[key]
                        });
                    }
                    return list;
                } else {
                    return [];
                }
            },
            domId() {
                return "file-" + this.uuid;
            },
            link() {
                return `/get/${this.uuid}/${this.filename}`;
            },
            mod() {
                return this.role == "mod" || this.role == "admin" || this.owner;
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
            },
            previewLink() {
                return "/pget/" + this.uuid;
            },
            fileType() {
                if ("mime_type" in this && this.mime_type) {
                    const type = this.mime_type.split("/")[0];
                    if (["audio", "video", "image"].includes(type)) {
                        return type;
                    } else {
                        return null;
                    }
                } else {
                    return null;
                }
            },
            image() {
                return this.fileType == "image";
            }
        },
        methods: {
            showMyInfo() {
                this.displayInfo(this.uuid);
            },
            hideMyInfo() {
                this.displayInfo("");
            },
            async deleteMe() {
                this.deleteStatus = "waiting";
                const files = [this.uuid];
                let result = await room.deleteFiles(files);
                result.success = result.results.length == 1 && result.results[0] == "ok";
                return result;
            },
            async banMe() {
                const date = new Date(
                    new Date().setFullYear(new Date().getFullYear() + 10)
                );
                const ban = {
                    file_bans: [
                        {
                            hash: this.hash
                        }
                    ],
                    reason: "quick ban",
                    end: Math.round(date.getTime() / 1000)
                };
                const result = await room.ban(ban);
                return result;
            },

            async banUploader() {
                const date = new Date(
                    new Date().setHours(new Date().getHours() + 1)
                );

                const ban = {
                    user_bans: [
                        {
                            bannee_id: this.uploader_id,
                            hell: false,
                            ip_bans: [
                                {
                                    ip_address: this.ip_address
                                }
                            ]
                        }
                    ],
                    reason: "quick ban",
                    end: Math.round(date.getTime() / 1000)
                };
                const result = await room.ban(ban);
                return result;
            }
        },

        components: {
            asyncButton: asyncButton
        }
    };
};
