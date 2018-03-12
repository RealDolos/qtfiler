"use strict";

import asyncButton from "./async-button-view";

export default {
    name: "settings",
    template: "#settings-template",
    props: ["saveSettings", "setSettingsCallback"],
    data() {
        return {
            show: false,
            settings: []
        };
    },
    components: {
        asyncButton: asyncButton
    },
    created() {
        this.setSettingsCallback(payload => {
            this.settings = payload.settings;
        });
    },
    methods: {
        toggle() {
            this.show = !this.show;
        },

        save() {
            return this.saveSettings({settings: this.settings});
        }
    },
    computed: {
        hidden() {
            return !this.show;
        }
    }
};
