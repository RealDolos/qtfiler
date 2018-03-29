"use strict";

function sleep(time) {
  return new Promise(resolve => setTimeout(resolve, time));
}

export default {
  name: "async-button",
  template: "#async-button-template",
  props: ["action", "defaultIcon"],
  data() {
    return {
      failCount: 0,
      status: "ready"
    };
  },
  computed: {
    readyString() {
      const iResult = parseInt(this.defaultIcon, 10);
      if (isNaN(iResult)) {
        return this.defaultIcon;
      }
      return String.fromCodePoint(iResult);
    },
    currentString() {
      switch (this.status) {
      case "waiting":
        return "⌛";

      case "failed":
        return "❌";

      case "succeeded":
        return "✓";
      default:
        return this.readyString;
      }
    }
  },
  methods: {
    async click() {
      if (this.status === "ready") {
        this.status = "waiting";
        const result = await this.action();
        if (result.success) {
          this.status = "succeeded";
          this.failCount = 0;
        }
        else {
          this.status = "failed";
          await sleep((2 ** this.failCount) * 1000);
          this.failCount += 1;
          this.status = "ready";
        }
      }
      else if (this.status === "succeeded") {
        this.status = "ready";
      }
    }
  }
};
