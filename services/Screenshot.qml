pragma Singleton

import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    readonly property list<string> modes: ["region", "window", "screen", "freeform"]

    // Capture mode of the screenshot tool, kept between uses and restarts
    // One of "region", "window", "screen" or "freeform"
    property string mode: "region"

    // Whether the screenshot tool copies to the clipboard instead of opening an editor, kept between uses and restarts
    // The clipboard shortcuts turn it on for a single screenshot without changing this
    property bool clipboard

    // Don't save over the stored choices before they've been read
    property bool loaded

    signal openRequested(freeze: bool, clipboardOnly: bool)

    function open(freeze = false, clipboardOnly = false): void {
        openRequested(freeze, clipboardOnly);
    }

    function save(): void {
        if (loaded)
            storage.setText(JSON.stringify({
                mode,
                clipboard
            }));
    }

    onModeChanged: save()
    onClipboardChanged: save()

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/screenshot.json`
        onLoaded: {
            // Fall back to the defaults if the file is unreadable, it gets rewritten on the next change
            try {
                const data = JSON.parse(text());
                if (root.modes.includes(data.mode))
                    root.mode = data.mode;
                root.clipboard = data.clipboard === true;
            } catch (e) {}
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
}
