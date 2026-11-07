pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Clipboard history backed by cliphist. Misland runs the recorder
// (`wl-paste --watch cliphist store`) unless clipboard.watch is off.
//
// Each entry: { line, id, text, image, ext, meta }. `line` is the raw
// `cliphist list` line, which decode and delete take on stdin.
Singleton {
    id: root

    property var entries: []
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/misland/clipboard"

    function refresh(): void {
        lister.running = true;
    }

    function search(query: string): var {
        const q = query.trim().toLowerCase();
        if (q === "") return entries;
        return entries.filter(e => e.text.toLowerCase().includes(q));
    }

    function copy(entry: var): void {
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", entry.line]);
    }

    function remove(entry: var): void {
        entries = entries.filter(e => e !== entry);
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist delete', "sh", entry.line]);
    }

    function wipe(): void {
        entries = [];
        Quickshell.execDetached(["sh", "-c", `cliphist wipe; rm -rf '${cacheDir}'`]);
    }

    // Where the decoded thumbnail of an image entry is cached.
    function thumbnailPath(entry: var): string {
        return `${cacheDir}/${entry.id}.${entry.ext}`;
    }

    function parse(text: string): var {
        return text.split("\n")
            .filter(line => line.includes("\t"))
            .slice(0, Config.clipboard.maxItems)
            .map(line => {
                const tab = line.indexOf("\t");
                const preview = line.slice(tab + 1);
                // cliphist previews images as "[[ binary data 12 KiB png 640x480 ]]".
                const img = preview.match(/^\[\[ binary data (.+?) (\w+) (\d+x\d+) \]\]$/);
                return {
                    line,
                    id: line.slice(0, tab),
                    text: img ? `Image · ${img[3]} · ${img[1]}` : preview,
                    image: img !== null,
                    ext: img ? img[2] : "",
                    meta: img ? img[2].toUpperCase() : ""
                };
            });
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = root.parse(text)
        }
    }

    // Records everything copied while the shell runs.
    Process {
        id: recorder
        running: Config.clipboard.watch
        command: ["wl-paste", "--watch", "cliphist", "store"]
        onExited: if (Config.clipboard.watch) restart.start()
    }

    Timer {
        id: restart
        interval: 2000
        onTriggered: recorder.running = Config.clipboard.watch
    }
}
