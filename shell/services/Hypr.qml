pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland dispatches in whichever syntax the running config uses: Lua
// configs (0.55+) take `hl.dsp.*` calls, hyprlang configs the classic form.
Singleton {
    // `target` is a workspace id or a selector such as "r+1".
    function focusWorkspace(target: var): void {
        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ workspace = ${JSON.stringify(target)} })`
            : `workspace ${target}`);
    }

    function exit(): void {
        Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit");
    }
}
