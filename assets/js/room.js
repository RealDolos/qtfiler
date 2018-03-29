"use strict";
/* globals window, document */

import Presence from "./presence";

export default class Room {
  constructor(socket) {
    this.room_id = window.config.room_id;
    this.presence = new Presence();
    this.createChannel(socket);
    this.role = "user";
    this.filter = "";
    this.owner = false;
    this.presenceSize = 0;
    this.settings = [];
  }

  initialise() {
    return new Promise((resolve, reject) => {
      return this.channel.join().
        receive("ok", () => {
          resolve(this.channel);
        }).
        receive("error", reject);
    });
  }

  push(method, data) {
    return new Promise((resolve, reject) => {
      this.channel.push(method, data).
        receive("ok", resolve).
        receive("error", reject);
    });
  }

  async deleteFiles(files) {
    try {
      const results = await this.push("delete", {files});
      this.fileList.setFileDeletionResults(files, results.results);
      console.log(`files deleted: ${results.results}`);
      return results;
    }
    catch (e) {
      this.fileList.setFileDeletionFailed(files);
      console.log(`failed to delete files: ${e}`);
      throw e;
    }
  }

  async ban(data) {
    try {
      const result = await this.push("ban", data);
      return result;
    }
    catch (e) {
      console.log(`failed to ban: ${e}`);
      throw e;
    }
  }

  initialiseUploader() {
    const uploadButton = document.getElementById("upload-button");
    const self = this;
    uploadButton.addEventListener("change", function() {
      const {files} = this;
      for (const file of files) {
        self.fileList.addUpload(file);
      }
      this.value = "";
    });

    window.addEventListener("drop", ev => {
      ev.preventDefault();
      ev.stopPropagation();
      return false;
    });

    window.addEventListener("dragover", ev => {
      ev.preventDefault();
      ev.stopPropagation();
      return false;
    });

    const dropzone = document.getElementById("file-dropzone");
    dropzone.addEventListener("drop", ev => {
      ev.preventDefault();
      ev.stopPropagation();
      const dt = ev.dataTransfer;
      if (dt.items) {
        for (const item of dt.items) {
          if (item.kind === "file") {
            this.fileList.addUpload(item.getAsFile());
          }
        }
      }
      else {
        // version that works in palememe
        for (const item of dt.files) {
          this.fileList.addUpload(item);
        }
      }
      return false;
    }, true);
  }

  createChannel(socket) {
    const channel = socket.channel(`room:${this.room_id}`, {});
    this.channel = channel;

    channel.on("files", payload => {
      payload.body.forEach(file => {
        this.fileList.addFile(file);
      });
    });

    channel.on("new_files", payload => {
      this.fileList.addNewFiles(payload.body);
    });

    channel.on("metadata", payload => {
      for (const uuid in payload) {
        const file = this.fileList.getFileByUUID(uuid);
        file.metadata.data = payload[uuid];
      }
    });

    channel.on("preview", payload => {
      for (const uuid in payload) {
        const file = this.fileList.getFileByUUID(uuid);
        file.previews = file.previews.concat(payload[uuid]);
      }
    });

    channel.on("role", payload => {
      this.role = payload.body;
    });

    channel.on("deleted", payload => {
      this.fileList.removeFile(payload.body);
    });

    channel.on("presence_state", payload => {
      this.presence.syncState(payload);
    });

    channel.on("presence_diff", payload => {
      this.presence.diffState(payload);
    });

    channel.on("owner", payload => {
      this.owner = payload.body;
    });
  }
}
