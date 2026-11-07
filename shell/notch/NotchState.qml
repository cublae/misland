pragma Singleton

import QtQuick
import Quickshell

// What the notch is showing. The panel and the launcher are exclusive:
// opening one closes the other.
Singleton {
    property bool expanded: false
    property bool launcher: false
    readonly property bool open: expanded || launcher

    onExpandedChanged: if (expanded) launcher = false
    onLauncherChanged: if (launcher) expanded = false

    function close(): void {
        expanded = false;
        launcher = false;
    }
}
