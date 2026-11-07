pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Desktop applications and a small ranked search over them.
Singleton {
    id: root

    readonly property list<DesktopEntry> all: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    function search(query: string): list<DesktopEntry> {
        const q = query.trim().toLowerCase();
        if (q === "") return all;
        return all
            .map(e => ({ e, s: score(e, q) }))
            .filter(r => r.s > 0)
            .sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name))
            .map(r => r.e);
    }

    function score(e: DesktopEntry, q: string): real {
        const name = e.name.toLowerCase();
        if (name.startsWith(q)) return 100;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 80;
        if (name.includes(q)) return 60;
        if (e.genericName.toLowerCase().includes(q)) return 40;
        if (e.keywords.some(k => k.toLowerCase().startsWith(q))) return 30;
        if (e.comment.toLowerCase().includes(q)) return 10;
        // Letters in order, e.g. "vsc" -> "Visual Studio Code".
        let i = 0;
        for (const c of name) if (c === q[i]) i++;
        return i === q.length ? 5 : 0;
    }

    function launch(e: DesktopEntry): void {
        if (e.runInTerminal)
            Quickshell.execDetached({ command: [...Config.launcher.terminal, ...e.command], workingDirectory: e.workingDirectory });
        else
            e.execute();
    }

    function icon(e: DesktopEntry): string {
        return Quickshell.iconPath(e?.icon ?? "", "application-x-executable");
    }
}
