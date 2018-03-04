//import "js/uploader.js";
import FileList from "./file-list";
import Presence from "./presence";

export default class Room {
    constructor(socket) {
        this.room_id = window.config.room_id;
        this.fileList = new FileList(this.room_id);
        this.presence = new Presence();
        const self = this;
        Room.createChannel(socket, this.room_id, this).then(channel => {
            self.channel = channel;
        });
        this.role = "user";
        this.filter = "";
        this.presenceSize = 0;
    }

    push(method, data) {
        return new Promise((resolve, reject) => {
            this.channel.push(method, data)
                .receive("ok", resolve)
                .receive("error", reject)
            ;
        });
    }

    async deleteFiles(files) {
        try {
            const results = await this.push("delete", {files: files})
            this.fileList.setFileDeletionResults(files, results.results);
            console.log("files deleted: " + results.results);
            return results;
        } catch (e) {
            this.fileList.setFileDeletionFailed(files);
            console.log("failed to delete files: " + e);
            throw e;
        }
   }

    async ban(data) {
        try {
            const result = await this.push("ban", data)
            return result;
        } catch (e) {
            console.log("failed to ban: " + e);
            throw e;
        }
   }

    initialiseUploader() {
        const uploadButton = document.getElementById("upload-button");
        const self = this;
        uploadButton.addEventListener("change", function() {
            const files = this.files;
            for (const file of files) {
                self.fileList.addUpload(file);
            }
            this.value = "";
        });

        window.addEventListener("drop", (ev) => {
            ev.preventDefault();
            ev.stopPropagation();
            return false;
        });

        window.addEventListener("dragover", (ev) => {
            ev.preventDefault();
            ev.stopPropagation();
            return false;
        });

        const dropzone = document.getElementById("file-dropzone");
        dropzone.addEventListener("drop", (ev) => {
            ev.preventDefault();
            ev.stopPropagation();
            const dt = ev.dataTransfer;
            if (dt.items) {
                for (let item of dt.items) {
                    if (item.kind == "file") {
                        this.fileList.addUpload(item.getAsFile());
                    }
                }
            } else {
                // version that works in palememe
                for (let item of dt.files) {
                    this.fileList.addUpload(item);
                }
            }
            return false;
        }, true);
    }

    static createChannel(socket, room_id, self) {
        return new Promise((resolve, reject) => {
            const channel = socket.channel("room:" + room_id, {});

            channel.on("files", payload => {
                payload.body.forEach(file => {
                    self.fileList.addFile(file);
                });
            });
        
            channel.on("role", payload => {
                self.role = payload.body;
            });
            
            channel.on("deleted", payload => {
                self.fileList.removeFile(payload.body);
            });

            channel.on("presence_state", payload => {
                self.presence.syncState(payload);
            });

            channel.on("presence_diff", payload => {
                self.presence.diffState(payload);
            });
        
            channel.join()
                .receive("ok", resp => {
                    resolve(channel);
                })
                .receive("error", reject)
            ;
        });
    }
}
