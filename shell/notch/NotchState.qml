pragma Singleton

import QtQuick
import Quickshell

// What the open notch is showing: "" (collapsed), "panel", "launcher" or
// "clipboard". Only one view is open at a time.
Singleton {
    property string view: ""

    readonly property bool open: view !== ""
    readonly property bool expanded: view === "panel"
    readonly property bool launcher: view === "launcher"
    readonly property bool clipboard: view === "clipboard"

    function show(name: string): void {
        view = name;
    }

    function toggle(name: string): void {
        view = view === name ? "" : name;
    }

    function close(): void {
        view = "";
    }
}
