"use strict";

import asyncButton from "./async-button-view";

const SHRUNK_LIMIT = 22;
const VALID_TYPES = Object.freeze(new Set(["audio", "video", "image"]));

export default function(room) {
  return {
    data() {
      // XXX sort out the uuid mess!
      const rv = Object.assign({}, room.fileList.searchFiles(this.uuid));
      delete rv.uuid;
      return rv;
    },
    name: "file",
    template: "#file-template",
    props: ["role", "uuid", "owner", "displayInfo", "displayInfoHere"],
    computed: {
      tagList() {
        if (this.metadata === null) {
          return [];
        }
        const {data: {format: {tags = {}} = {}} = {}} = this.metadata | {};
        return Object.entries(tags);
      },
      domId() {
        return `file-${this.uuid}`;
      },
      link() {
        return `/get/${encodeURIComponent(this.uuid)}/${encodeURIComponent(this.filename)}`;
      },
      mod() {
        return this.role === "mod" || this.role === "admin" || this.owner;
      },
      formattedExpirationDate() {
        return (new Date(this.expiration_date)).toLocaleString();
      },
      shrunken_ip() {
        return this.ip_address.substring(0, SHRUNK_LIMIT);
      },
      fileType() {
        if ("mime_type" in this && this.mime_type) {
          const [type] = this.mime_type.split("/");
          if (VALID_TYPES.has(type)) {
            return type;
          }
          return null;
        }
        return null;
      },
      imageThumbPreviewLink() {
        return `/pget/${encodeURIComponent(this.uuid)}/image_thumbnail`;
      },
      videoThumbPreviewLink() {
        return `/pget/${encodeURIComponent(this.uuid)}/video_thumbnail`;
      },
      videoPreviews() {
        return this.previews.filter(
          preview => preview.type === "video_thumbnail");
      },
      imagePreviews() {
        return this.previews.filter(
          preview => preview.type === "image_thumbnail");
      }
    },
    methods: {
      showMyInfo() {
        this.displayInfo(this.uuid);
      },
      hideMyInfo() {
        this.displayInfo("");
      },
      async deleteMe() {
        this.deleteStatus = "waiting";
        const files = [this.uuid];
        const result = await room.deleteFiles(files);
        result.success = result.results.length === 1 &&
          result.results[0] === "ok";
        return result;
      },
      async banMe() {
        const date = new Date(
          new Date().setFullYear(new Date().getFullYear() + 10)
        );
        const ban = {
          file_bans: [
            {
              hash: this.hash
            }
          ],
          reason: "quick ban",
          end: Math.round(date.getTime() / 1000)
        };
        const result = await room.ban(ban);
        return result;
      },

      async banUploader() {
        const date = new Date(
          new Date().setHours(new Date().getHours() + 1)
        );

        const ban = {
          user_bans: [
            {
              bannee_id: this.uploader_id,
              hell: false,
              ip_bans: [
                {
                  ip_address: this.ip_address
                }
              ]
            }
          ],
          reason: "quick ban",
          end: Math.round(date.getTime() / 1000)
        };
        const result = await room.ban(ban);
        return result;
      }
    },

    components: {
      asyncButton
    }
  };
}
