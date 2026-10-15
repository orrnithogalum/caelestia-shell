pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import qs.services

Singleton {
    id: root

    // Capture mode of the screenshot tool, kept between uses
    // One of "region", "window", "screen" or "freeform"
    property alias mode: props.mode

    // Whether the Print bind below is currently applied
    property bool printBound

    signal openRequested(freeze: bool, clipboardOnly: bool)

    function open(freeze = false, clipboardOnly = false): void {
        openRequested(freeze, clipboardOnly);
    }

    // Replaces any Print bind from the Hyprland config with the screenshot tool (frozen, copies to clipboard)
    function bindPrint(): void {
        if (!GlobalConfig.services.bindPrintScreen)
            return;

        if (Hypr.usingLua)
            Hypr.extras.batchMessage(['eval hl.unbind("Print")', 'eval hl.bind("Print", hl.dsp.global("caelestia:screenshotFreezeClip"))']);
        else
            Hypr.extras.batchMessage(["keyword unbind ,Print", "keyword bind ,Print,global,caelestia:screenshotFreezeClip"]);
        printBound = true;
    }

    Component.onCompleted: bindPrint()

    PersistentProperties {
        id: props

        property string mode: "region"

        reloadableId: "screenshot"
    }

    Connections {
        function onConfigReloaded(): void {
            // Config reloads reset runtime binds
            root.printBound = false;
            root.bindPrint();
        }

        function onUsingLuaChanged(): void {
            root.bindPrint();
        }

        target: Hypr
    }

    Connections {
        function onBindPrintScreenChanged(): void {
            if (GlobalConfig.services.bindPrintScreen) {
                root.bindPrint();
            } else if (root.printBound) {
                // Reload the Hyprland config to bring back its own Print bind
                root.printBound = false;
                Hypr.extras.message("reload");
            }
        }

        target: GlobalConfig.services
    }
}
