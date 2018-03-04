"use strict";

import Upload from "./upload";
import File from "./file";

export default class FileList {
    constructor(room_id) {
        this.uploads = [];
        this.files = [];
        this.status = 0;
        this.room_id = room_id;
        this.current = null;
        this.currentID = "";
    }

    sleep(time) {
        return new Promise(resolve => setTimeout(resolve, time));
    }

    async wakeUploader() {
        if (this.status) {
            return {
                success: true
            };
        }

        this.status += 1;

        try {
            await this.performUploads();
        } finally {
            // todo: catch
            this.status -= 1;
        }

        return {
            success: true
        };
    }

    pause(id) {
        if (this.currentID == id && this.current != null) {
            this.current.abort();
        }
    }

    getNextUpload() {
        for (let upload of this.uploads) {
            if (!upload.paused) {
                return upload;
            }
        }
        return null;
    }

    async performUploads() {
        let upload = null;
        while ((upload = this.getNextUpload()) !== null) {
            try {
                const result = await this.upload(upload);
                this.current = null;

                if (result.done) {
                    this.uploads.shift();
                } else {
                    if ("offset" in result) {
                        upload.uploaded = result.offset;
                    }
                }
            } catch(e) {
                if (!e.aborted) {
                    await this.sleep((2 ** upload.attempt) * 1000);
                    upload.attempt += 1;
                }
            }
        }
        this.current = null;
    }

    upload(upload) {
        const offset = upload.uploaded;

        let query =
            "room_id=" + encodeURIComponent(this.room_id) +
            "&filename=" + encodeURIComponent(upload.file.name) +
            "&upload_id=" + encodeURIComponent(upload.id) +
            "&offset=" + encodeURIComponent(offset) +
            "&size=" + encodeURIComponent(upload.file.size);

        if (upload.file.type) {
            query += "&content_type=" + upload.file.type;
        }

        return new Promise((resolve, reject) => {
            const req = new XMLHttpRequest();
            this.current = req;
            this.currentID = upload.id;
            req.open("POST", "/api/upload?" + query, true);
            req.setRequestHeader("Content-Type", "application/octet-stream");

            const progress = (ev) => {
                if (ev.lengthComputable) {
                    upload.uploaded = ev.loaded + offset;
                }
            };

            req.upload.addEventListener("progress", progress);

            req.addEventListener("load", (ev) => {
                req.upload.removeEventListener("progress", progress);
                resolve(JSON.parse(req.response));
            });

            req.addEventListener("error", (ev) => {
                req.upload.removeEventListener("progress", progress);
                reject({
                    done: false,
                    success: false,
                    aborted: false
                });
            });

            req.addEventListener("abort", (ev) => {
                req.upload.removeEventListener("progress", progress);
                reject({
                    success: false,
                    aborted: true,
                    done: false
                });
            });

            if (upload.paused) {
                reject({
                    success: false,
                    done: false,
                    aborted: true
                });
            } else {
                req.send(upload.file.slice(offset));
            }
        });
    }

    async addUpload(name) {
        const upload = new Upload(name);
        this.uploads.push(upload);
        await this.wakeUploader();
    }

    static search(idKey, items, id, cont) {
        for (let i = 0; i < items.length; i++) {
            if (items[i][idKey] == id) {
                return cont(items[i], i);
            }
        }
        return null;
    }

    searchUploads(id, cont) {
        return FileList.search("id", this.uploads, id, cont);
    }

    searchFiles(id, cont) {
        return FileList.search("uuid", this.files, id, cont);
    }

    setFileDeletionFailed(uuids) {
        for (let file of this.files.reverse()) {
            if (uuids[uuids.length - 1] == file.uuid) {
                file.deleteStatus = "failed";
                uuids.pop();
            }
        }
    }

    setFileDeletionResults(uuids_original, results_original) {
        let uuids = uuids_original.slice(0);
        let results = results_original.slice(0);
        for (let file of this.files.reverse()) {
            if (uuids[uuids.length - 1] == file.uuid) {
                if (results[results.length - 1] == "ok") {
                    file.deleteStatus = "succeeded";
                } else {
                    file.deleteStatus = "failed";
                }
                results.pop();
                uuids.pop();
            }
        }
    }

    getDeletedFiles() {
        const result = [];
        for (let file of this.files) {
            if (file.marked) {
                file.deleteStatus = "waiting";
                result.push(file.uuid);
            }
        }
        return result;
    }

    progressUpload(id, uploaded, total) {
        this.searchUploads(id, (upload, i) => {
            upload.uploaded = uploaded;
            upload.total = total;
        });
    }

    completeUpload(id) {
        this.searchUploads(id, (upload, i) => {
            this.uploads.splice(i, 1);
        });
    }

    removeFile(uuid) {
        this.searchFiles(uuid, (file, i) => {
            this.files.splice(i, 1);
        });
    }

    addFile(data) {
        const file = File.create(data);
        this.files.unshift(file);
    }
}
