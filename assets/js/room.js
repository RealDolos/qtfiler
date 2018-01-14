//import "js/uploader.js";
const qq = require("fine-uploader/lib/core");
const dnd = require("fine-uploader/lib/dnd");
import socket from "./socket";


const uploading = {};

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
            uploading[id] = {
                name: name
            };
            const upload = document.createElement("div");
            upload.setAttribute("id", "upload-" + id);
            const uploadText = document.createTextNode(name + " 0%");
            upload.appendChild(uploadText);
            document.getElementById("uploads").appendChild(upload);
            return true;
        },
        onProgress: function(id, name, uploaded, total) {
            const fileProgress = uploading[id];
            const progress = Math.round(100 * uploaded / total);
            const uploadText = document.createTextNode(fileProgress.name + " " + progress + "%");
            const upload = document.getElementById("upload-" + id);
            if (upload.firstChild) {
                upload.removeChild(upload.firstChild);
            }
            upload.appendChild(uploadText);
        },
        onComplete: function(id, name, response, xhr) {
            const upload = document.getElementById("upload-" + id);
            document.getElementById("uploads").removeChild(upload);
            delete uploading[id];
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

