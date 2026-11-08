pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire

// What is recording right now, for the privacy indicators:
//   microphone    an app records audio from an input (not desktop audio)
//   camera        a process has a /dev/video* device open
//   screenSharing a screencast through xdg-desktop-portal-hyprland
Singleton {
    id: root

    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream)

    // Capture streams of the desktop audio set stream.capture.sink; those
    // are not the microphone.
    readonly property var microphoneApps: streams
        .filter(n => n.properties?.["media.class"] === "Stream/Input/Audio"
            && n.properties?.["stream.capture.sink"] !== "true")
        .map(n => n.properties?.["application.name"] || n.name)

    readonly property bool microphone: microphoneApps.length > 0
    property bool camera: false
    readonly property bool screenSharing: portalCast || hyprlandCast

    // xdph publishes a video source node only while a cast is running.
    readonly property bool portalCast: Pipewire.nodes.values.some(n => n.name.includes("xdg-desktop-portal"))
    // Hyprland also reports "screencast>>1,…" / "screencast>>0,…".
    property bool hyprlandCast: false

    readonly property bool any: microphone || camera || screenSharing

    // Node properties are only filled in for tracked nodes.
    PwObjectTracker {
        objects: root.streams
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "screencast") root.hyprlandCast = event.data.startsWith("1");
        }
    }

    // Browsers usually open the camera directly instead of through PipeWire,
    // so look for open video devices.
    Timer {
        running: true
        triggeredOnStart: true
        interval: 3000
        repeat: true
        onTriggered: if (!cameraCheck.running) cameraCheck.running = true
    }

    Process {
        id: cameraCheck
        command: ["sh", "-c", "find /proc/[0-9]*/fd -maxdepth 1 -lname '/dev/video*' 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: root.camera = text.trim() !== ""
        }
    }
}
