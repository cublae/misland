pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // playerctld mirrors other players; showing it would duplicate them.
    readonly property list<MprisPlayer> players: Mpris.players.values
        .filter(p => !p.dbusName.includes("playerctld"))

    property MprisPlayer manual: null
    readonly property MprisPlayer player: {
        if (manual && players.includes(manual)) return manual;
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }

    // Cycle through players when more than one is open.
    function next(): void {
        if (players.length < 2) return;
        manual = players[(players.indexOf(player) + 1) % players.length];
    }

    function formatTime(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        const m = Math.floor(s / 60);
        return `${m}:${String(s % 60).padStart(2, "0")}`;
    }

    // MPRIS does not push position updates; ask for them while playing.
    Timer {
        running: root.player?.isPlaying ?? false
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }
}
