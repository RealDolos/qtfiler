"use strict";

import {Presence as PhoenixPresence} from "phoenix";

export default class Presence {
    constructor() {
        this.presences = {};
    }

    syncState(state) {
        this.presences = PhoenixPresence.syncState(this.presences, state);
    }

    diffState(diff) {
        this.presences = PhoenixPresence.syncDiff(this.presences, diff);
    }
}
