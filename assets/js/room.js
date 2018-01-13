//import "js/uploader.js";
var qq = require("fine-uploader/lib/core");
var dnd = require("fine-uploader/lib/dnd");


var uploading = {};

var uploader = new qq.FineUploaderBasic({
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
            var upload = document.createElement("div");
            upload.setAttribute("id", "upload-" + id);
            var uploadText = document.createTextNode(name + " 0%");
            upload.appendChild(uploadText);
            document.getElementById("uploads").appendChild(upload);
            return true;
        },
        onProgress: function(id, name, uploaded, total) {
            var fileProgress = uploading[id];
            var progress = Math.round(100 * uploaded / total);
            var uploadText = document.createTextNode(fileProgress.name + " " + progress + "%");
            var upload = document.getElementById("upload-" + id);
            if (upload.firstChild) {
                upload.removeChild(upload.firstChild);
            }
            upload.appendChild(uploadText);
        },
        onComplete: function(id, name, response, xhr) {
            var upload = document.getElementById("upload-" + id);
            document.getElementById("uploads").removeChild(upload);
            delete uploading[id];
        }
    }
});

var dragAndDrop = new dnd.DragAndDrop({
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

console.log("haha");
