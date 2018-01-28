"use strict";

const PPresence = require("phoenix").Presence;

class Presence {
    constructor() {
        this.presences = {};
    }

    syncState(state) {
        this.presences = PPresence.syncState(this.presences, state);
    }

    diffState(diff) {
        this.presences = PPresence.syncDiff(this.presences, diff);
    }
}

module.exports = Presence;
