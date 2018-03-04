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
    methods: {
        async click() {
            if (this.status == "ready") {
                this.status = "waiting";
                const result = await this.action();
                if (result.success) {
                    this.status = "succeeded";
                } else {
                    this.status = "failed";
                    await sleep((2 ** this.failCount) * 1000);
                    this.failCount += 1;
                    this.status = "ready";
                }
            }
        }
    }
};
