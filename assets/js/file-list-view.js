"use strict";

import file from "./file-view";
import upload from "./upload-view";
import lodash from "lodash";

export default function(room) {
    return {
        name: "fileList",
        template: "#file-list-template",
        props: ["role", "filter", "owner", "settings"],
        data() {
            return room.fileList;
        },
        components: {
            file: file(room),
            upload: upload(room)
        },
        
        computed: {
            hovery() {
                for (let setting of this.settings) {
                    if (setting.key == "hover") {
                        return setting.value;
                    }
                }
                return false;
            },
            filteredFiles() {
                var bools = [];
                var filter2 = this.filter.split(" ");
                for(var i = 0; i < filter2.length; i++) {
                    if(filter2[i][0] == "-") {
                        bools[i] = false;
                        filter2[i] = filter2[i].substring(1);
                    }
                    else {
                        bools[i] = true;
                    }
                }
                return this.files.filter((f) => {
                    for(var i = 0; i < filter2.length; i++) {
                        if(filter2[i].search("user:") >= 0) { //checks if filtering by user
                            if(!((f.uploader.toUpperCase().search(filter2[i].substring(5).toUpperCase()) == 0) == bools[i])) {
                                return 0;
                            }
                          }
                          else {
                              if(!(f.filename.toUpperCase().search(filter2[i].toUpperCase()) >= 0 == bools[i])) {
                                  return 0;
                              }
                          }
                      }
                    
                    return 1;});
            },
            filesLength() {
                return this.files.length;
            },
            filteredFilesLength() {
                return this.filteredFiles.length;
            }
        },
        methods: {
            mouseMove(e) {
                if (!this.hovery) {
                    return;
                }

                let target = e.target;

                while (true) {
                    if (target == e.currentTarget) {
                        return;
                    } else {
                        if (target.classList.contains("file-container")) {
                            const thumb = target.firstChild.nextElementSibling;

                            if (thumb) {
                                thumb.style.setProperty("transform", `translate(${e.clientX + 1}px, ${e.clientY + 1}px)`);
                            }

                            return;
                        } else {
                            target = target.parentElement;
                        }
                    }
                }
            },
            async wake() {
                return await this.$data.wakeUploader();
            },
            async pause(id) {
                return await this.$data.pause(id);
            },
            displayInfo: lodash.debounce(function(uuid) {
                this.info = uuid;
            }, 125)
         }
    };
};
