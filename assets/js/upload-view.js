"use strict";

import asyncButton from "./async-button-view";

export default function() {
  return {
    name: "upload",
    template: "#upload-template",
    props: ["role", "index", "wake", "pause", "upload"],
    data() {
      return {
        id: this.upload.id,
      };
    },
    computed: {
      progress() {
        return Math.round(
          (this.upload.uploaded / this.upload.file.size) * 100);
      },
      domId() {
        return `upload-${this.id}`;
      },
      isOdd() {
        return this.index % 2;
      },
      isEven() {
        return (this.index + 1) % 2;
      },
      running() {
        return !this.upload.paused;
      }
    },
    components: {
      asyncButton
    },
    methods: {
      async toggle() {
        this.upload.paused = !this.upload.paused;
        if (this.upload.paused) {
          this.pause(this.id);
        }
        return await this.wake();
      }
    }
  };
}
