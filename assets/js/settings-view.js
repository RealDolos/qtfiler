"use strict";

export default function() {
    return {
        name: "settings",
        template: "#settings-template",
        props: ["model", "saveSettings", "setSettingsCallback"],
        data() {
            return {
                
            };
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
