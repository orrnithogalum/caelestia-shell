pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property bool trayEnabled: Config.bar.entries.values.some(e => e.id === "tray" && e.enabled)

    function setTrayEnabled(enabled: bool): void {
        const list = GlobalConfig.bar.entries;
        let found = false;
        for (let i = 0; i < list.count; i++) {
            const item = list.at(i);
            if (item.id === "tray") {
                item.enabled = enabled;
                found = true;
            }
        }

        // Entry was removed from the config, add it back before the clock (default position)
        if (!found && enabled)
            list.insert({
                id: "tray",
                enabled: true
            }, list.values.findIndex(e => e.id === "clock"));
    }

    title: Tr.tr("Tray")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.trCtx("Enabled", "toggle label")
            subtext: Tr.tr("Show the system tray in the taskbar")
            checked: root.trayEnabled
            onToggled: root.setTrayEnabled(checked)
        }

        // Appearance
        SectionHeader {
            text: Tr.tr("Appearance")
        }

        ToggleRow {
            first: true
            text: Tr.trCtx("Background", "taskbar tray: draw a background behind the tray")
            disabled: !root.trayEnabled
            checked: Config.bar.tray.background
            onToggled: GlobalConfig.bar.tray.background = checked
        }

        ToggleRow {
            // TRANSLATORS: tint system tray icons with the theme accent colour
            text: Tr.tr("Recolour icons")
            disabled: !root.trayEnabled
            checked: Config.bar.tray.recolour
            onToggled: GlobalConfig.bar.tray.recolour = checked
        }

        ToggleRow {
            last: true
            text: Tr.trCtx("Compact", "taskbar tray layout")
            disabled: !root.trayEnabled
            checked: Config.bar.tray.compact
            onToggled: GlobalConfig.bar.tray.compact = checked
        }

        // Behaviour
        SectionHeader {
            text: Tr.tr("Behaviour")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.tr("Popout on hover")
            subtext: Tr.tr("Show the tray menu popout when hovering")
            disabled: !root.trayEnabled
            checked: Config.bar.popouts.tray
            onToggled: GlobalConfig.bar.popouts.tray = checked
        }
    }
}
