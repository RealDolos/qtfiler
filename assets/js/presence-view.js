"use strict";

export default function(room) {
    return {
        name: "presence",
        template: "#presence-template",
        props: ["role", "presenceHidden"],
        data() {
            return room.presence;
        },
        methods: {
            togglePresence() {
                this.$emit("toggle-presence");
            }
        },
        computed: {
            hidden() {
                return this.presenceHidden;
            }
        }
    };
};
