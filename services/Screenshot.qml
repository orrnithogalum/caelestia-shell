pragma Singleton

import Quickshell

Singleton {
    id: root

    // Capture mode of the screenshot tool, kept between uses
    // One of "region", "window", "screen" or "freeform"
    property alias mode: props.mode

    // Whether the screenshot tool copies to the clipboard instead of opening an editor, kept between uses
    // The clipboard shortcuts turn it on for a single screenshot without changing this
    property alias clipboard: props.clipboard

    signal openRequested(freeze: bool, clipboardOnly: bool)

    function open(freeze = false, clipboardOnly = false): void {
        openRequested(freeze, clipboardOnly);
    }

    PersistentProperties {
        id: props

        property string mode: "region"
        property bool clipboard

        reloadableId: "screenshot"
    }
}
