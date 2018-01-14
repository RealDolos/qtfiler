//import "js/uploader.js";
var qq = require("fine-uploader/lib/core");
var dnd = require("fine-uploader/lib/dnd");
import socket from "./socket";

var uploader = new qq.FineUploaderBasic({
    request: {
        endpoint: "/api/upload",
        params: {"room_id": window.config.room_id},
        inputName: "file"
    },
    retry: {
        enableAuto: true
    },
    maxConnections: 1
});

var dragAndDrop = new dnd.DragAndDrop({
    dropZoneElements: [document.querySelector("#file-dropzone"), document.body],
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

function resizeElementHeight(element) {
    var height = 0;
    var body = window.document.body;
    if (window.innerHeight) {
        height = window.innerHeight;
    } else if (body.parentElement.clientHeight) {
        height = body.parentElement.clientHeight;
    } else if (body && body.clientHeight) {
        height = body.clientHeight;
    }
    element.style.height = ((height - element.offsetTop) + "px");
}

window.addEventListener("resize", function() {
    resizeElementHeight(document.querySelector("#file-dropzone"));
});


resizeElementHeight(document.querySelector("#file-dropzone"));
