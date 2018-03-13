"use strict";

import asyncButton from "./async-button-view";

export default {
    name: "settings",
    template: "#settings-template",
    props: ["saveSettings", "setSettingsCallback", "mod", "setUserSettings"],

    data() {
        return {
            show: false,
            settings: [],
            userSettings: [
            ]
        };
    },

    components: {
        asyncButton: asyncButton
    },

    mounted() {
        this.setSettingsCallback(payload => {
            this.settings = payload.settings;
        });

        if (localStorage) {
            this.userSettings = JSON.parse(localStorage.getItem("userSettings"));
        }

        if (!this.userSettings || this.userSettings.length == 0) {
            this.userSettings = [
                {
                    name: "Hovery thumbs",
                    key: "hover",
                    value: false
                }
            ];
        }

        this.setUserSettings(this.userSettings);
    },

    methods: {
        toggle() {
            this.show = !this.show;
        },

        save() {
            return this.saveSettings({settings: this.settings});
        },

        saveUser() {
            this.setUserSettings(this.userSettings);
            if (localStorage) {
                localStorage.setItem("userSettings", JSON.stringify(this.userSettings));
                return {
                    success: true
                };
            } else {
                return {
                    success: false
                };
            }
        }
    },

    computed: {
        hidden() {
            return !this.show;
        }
    }
};
