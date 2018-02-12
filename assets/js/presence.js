"use strict";

import {PPresence} from "phoenix";

export default class Presence {
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
