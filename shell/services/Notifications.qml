pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config

// Notification daemon (org.freedesktop.Notifications). Every notification
// is tracked for the history in the notch; `popups` holds the ids that are
// currently shown on the right edge.
Singleton {
    id: root

    readonly property list<Notification> history: server.trackedNotifications.values.slice().reverse()
    readonly property alias popups: popupModel

    // Notification exposes no arrival time, so keep one per id.
    property var received: ({})

    function find(id: int): Notification {
        return server.trackedNotifications.values.find(n => n.id === id) ?? null;
    }

    function removePopup(id: int): void {
        for (let i = 0; i < popupModel.count; i++) {
            if (popupModel.get(i).nid === id) {
                popupModel.remove(i);
                break;
            }
        }
    }

    // Popup timed out or was closed by the user.
    function hidePopup(id: int): void {
        removePopup(id);
        // Transient notifications never reach the history.
        const n = find(id);
        if (n?.transient) n.expire();
    }

    // Run the default action if there is one, then remove the notification.
    function activate(n: Notification): void {
        n.actions.find(a => a.identifier === "default")?.invoke();
        n.dismiss();
    }

    function clearAll(): void {
        for (const n of server.trackedNotifications.values.slice()) n.dismiss();
    }

    function age(id: int): string {
        const t = received[id];
        if (!t) return "";
        const min = Math.floor((Time.now.getTime() - t) / 60000);
        return min < 1 ? "now" : min < 60 ? `${min}m` : min < 1440 ? `${Math.floor(min / 60)}h` : `${Math.floor(min / 1440)}d`;
    }

    ListModel { id: popupModel }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            root.received[n.id] = Date.now();

            // A replacement keeps its id; show it again instead of twice.
            root.removePopup(n.id);
            popupModel.insert(0, { nid: n.id });

            const all = server.trackedNotifications.values;
            for (let i = 0; i < all.length - Config.notifications.maxHistory; i++) all[i].dismiss();

            n.closed.connect(() => {
                root.removePopup(n.id);
                delete root.received[n.id];
            });
        }
    }
}
