pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.containers
import qs.components.misc
import qs.services

Scope {
    LazyLoader {
        id: root

        property bool freeze
        property bool closing
        property bool clipboardOnly

        function open(freeze: bool, clipboardOnly: bool): void {
            root.freeze = freeze;
            root.closing = false;
            root.clipboardOnly = clipboardOnly;
            root.activeAsync = true;
        }

        Variants {
            model: Screens.screens

            StyledWindow {
                id: win

                required property ShellScreen modelData

                screen: modelData
                name: "area-picker"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: root.closing ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
                mask: root.closing ? empty : null

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                Region {
                    id: empty
                }

                Picker {
                    loader: root
                    screen: win.modelData
                }
            }
        }
    }

    IpcHandler {
        function open(): void {
            root.open(false, false);
        }

        function openFreeze(): void {
            root.open(true, false);
        }

        function openClip(): void {
            root.open(false, true);
        }

        function openFreezeClip(): void {
            root.open(true, true);
        }

        target: "picker"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "screenshot"
        description: "Open screenshot tool"
        onPressed: root.open(false, false)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "screenshotFreeze"
        description: "Open screenshot tool (freeze mode)"
        onPressed: root.open(true, false)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "screenshotClip"
        description: "Open screenshot tool (clipboard)"
        onPressed: root.open(false, true)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "screenshotFreezeClip"
        description: "Open screenshot tool (freeze mode, clipboard)"
        onPressed: root.open(true, true)
    }
}
