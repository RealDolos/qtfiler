//import "js/uploader.js";
const FileList = require("./file-list");
const qq = require("fine-uploader/lib/core");
const dnd = require("fine-uploader/lib/dnd");

class Room {
    constructor(socket) {
        this.room_id = window.config.room_id;
        this.fileList = new FileList();
        const self = this;
        Room.createChannel(socket, this.room_id, this).then(channel => {
            self.channel = channel;
        });
        this.uploader = Room.createUploader(this.fileList, this.room_id);
        this.dnD = Room.createDnD(this.uploader);
        this.role = "user";
        this.filter = "";
    }

    push(method, data) {
        return new Promise((resolve, reject) => {
            this.channel.push(method, data)
                .receive("ok", resolve)
                .receive("error", reject)
            ;
        });
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
        
            channel.join()
                .receive("ok", resp => {
                    resolve(channel);
                })
                .receive("error", reject)
            ;
        });
    }

    static createUploader(fileList, room_id) {
        const uploader = new qq.FineUploaderBasic({
            request: {
                endpoint: "/api/upload",
                inputName: "file"
            },

            retry: {
                enableAuto: true
            },

            button: document.getElementById("upload-button"),

            callbacks: {
                onSubmitted: function(id, name) {
                    fileList.addUpload(id, name);
                    return true;
                },

                onProgress: function(id, name, uploaded, total) {
                    fileList.progressUpload(id, uploaded, total);
                },

                onComplete: function(id, name, response, xhr) {
                    fileList.completeUpload(id);
                },

                onSubmit: function(id, name) {
                    this.setParams({
                        "room_id": room_id,
                        "mime_type": uploader.getFile(id).type
                    });
                }
            },

            maxConnections: 1
        });

        return uploader;
    }

    static createDnD(uploader) {
        const dragAndDrop = new dnd.DragAndDrop({
            dropZoneElements: [document.getElementById("file-dropzone")],

            callbacks: {
                processingDroppedFiles: function() {
                    //TODO: display some sort of a "processing" or spinner graphic
                },
                processingDroppedFilesComplete: function(files, dropTarget) {
                    //TODO: hide spinner/processing graphic

                    uploader.addFiles(files); //this submits the dropped files to Fine Uploader
                }
            }
        });

        return dragAndDrop;
    }
}

module.exports = Room;
