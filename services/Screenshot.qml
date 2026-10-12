pragma Singleton

import Quickshell

Singleton {
    id: root

    // Capture mode of the screenshot tool, kept between uses
    // One of "region", "window", "screen" or "freeform"
    property alias mode: props.mode

    signal openRequested(freeze: bool, clipboardOnly: bool)

    function open(freeze = false, clipboardOnly = false): void {
        openRequested(freeze, clipboardOnly);
    }

    PersistentProperties {
        id: props

        property string mode: "region"

        reloadableId: "screenshot"
    }
}
