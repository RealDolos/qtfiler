"use strict";

module.exports = (room) => {
    return {
        name: "presence",
        template: "#presence-template",
        props: ["role"],
        data() {
            return room.presence;
        }
    };
};
