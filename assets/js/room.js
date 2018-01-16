//import "js/uploader.js";
const socket = require("./socket");
const FileList = require("./file-list");
const qq = require("fine-uploader/lib/core");
const dnd = require("fine-uploader/lib/dnd");
const fileList = new FileList(document.getElementById("file-list"));
const room_id = window.config.room_id;
const channel = socket.channel("room:" + room_id, {});

channel.on("files", payload => {
    payload.body.forEach(file => {
        fileList.addFile(file);
    });
    fileList.render();
});

channel.on("role", payload => {
    fileList.role = payload.body;
    fileList.render();
});

channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp); })
    .receive("error", resp => { console.log("Unable to join", resp); });


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
            fileList.render();
            return true;
        },
        onProgress: function(id, name, uploaded, total) {
            fileList.progressUpload(id, uploaded, total);
            fileList.render();
        },
        onComplete: function(id, name, response, xhr) {
            fileList.completeUpload(id);
            fileList.render();
        },
        onSubmit: function(id, name) {
            this.setParams({
                "room_id": window.config.room_id,
                "mime_type": uploader.getFile(id).fileType
            });
        }
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
