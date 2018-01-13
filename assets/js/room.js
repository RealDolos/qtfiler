//import "js/uploader.js";
var qq = require("fine-uploader/lib/core");
var dnd = require("fine-uploader/lib/dnd");

var uploader = new qq.FineUploaderBasic({
    request: {
        endpoint: "/api/upload",
        params: {"room_id": window.config.room_id},
        inputName: "file"
    },
    retry: {
        enableAuto: true
    },
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
