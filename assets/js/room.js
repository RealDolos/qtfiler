//import "js/uploader.js";
const qq = require("fine-uploader/lib/core");
const dnd = require("fine-uploader/lib/dnd");
import FileList from "./file-list";
import socket from "./socket";


const fileList = new FileList(document.getElementById("uploads"));
let room_id = window.config.room_id;
let channel = socket.channel("room:" + room_id, {});

channel.on("files", payload => {
    payload.body.forEach(file => {
        fileList.addFile(file);
    });
});

channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp); })
    .receive("error", resp => { console.log("Unable to join", resp); });


const uploader = new qq.FineUploaderBasic({
    request: {
        endpoint: "/api/upload",
        params: {"room_id": window.config.room_id},
        inputName: "file"
    },
    retry: {
        enableAuto: true
    },
    button: document.getElementById("submit"),
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
        }
    },
    maxConnections: 1
});

const dragAndDrop = new dnd.DragAndDrop({
    dropZoneElements: [document.querySelector("#file-dropzone")],
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

