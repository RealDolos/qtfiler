"use strict";

export default function(room) {
    return {
        name: "presence",
        template: "#presence-template",
        props: ["role"],
        data() {
            return room.presence;
        }
    };
};
