//import "js/uploader.js";
const FileList = require("./file-list");
const Presence = require("./presence");

class Room {
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
        this.topid = 0;
    }

    push(method, data) {
        return new Promise((resolve, reject) => {
            this.channel.push(method, data)
                .receive("ok", resolve)
                .receive("error", reject)
            ;
        });
    }

    initialiseUploader() {
        const uploadButton = document.getElementById("upload-button");
        uploadButton.addEventListener("change", handleFiles, false);
        const self = this;
        function handleFiles() {
            const files = this.files;
            for (const file of files) {
                self.fileList.addUpload(self.topid, file);
                self.topid += 1;
            }
        }
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

module.exports = Room;
