pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.effects
import qs.services

MouseArea {
    id: root

    required property LazyLoader loader
    required property ShellScreen screen

    readonly property string mode: Screenshot.mode
    readonly property bool hasSelection: mode !== "freeform" && (mode !== "window" || onClient)
    property bool capturing // Waiting for a frame to save, hides everything
    property bool done // A capture was made, the tool is closing

    property bool onClient

    property real realBorderWidth: onClient ? (Hypr.options["general:border_size"] ?? 1) : 2
    property real realRounding: onClient ? (Hypr.options["decoration:rounding"] ?? 0) : 0

    property real ssx
    property real ssy

    property real sx: 0
    property real sy: 0
    property real ex: screen.width
    property real ey: screen.height

    property real rsx: Math.min(sx, ex)
    property real rsy: Math.min(sy, ey)
    property real sw: Math.abs(sx - ex)
    property real sh: Math.abs(sy - ey)

    property var lassoPoints: []

    property list<var> clients: {
        const mon = Hypr.monitorFor(screen);
        if (!mon)
            return [];

        const special = mon.lastIpcObject?.specialWorkspace;
        const wsId = special?.name ? special.id : mon.activeWorkspace?.id;
        if (wsId === undefined)
            return [];

        return Hypr.toplevelsForWs(wsId).sort((a, b) => {
            // Pinned first, then fullscreen, then floating, then any other
            const ac = a?.lastIpcObject;
            const bc = b?.lastIpcObject;
            if (!ac || !bc)
                return !ac - !bc; // Missing IPC last
            return (bc.pinned - ac.pinned) || ((bc.fullscreen !== 0) - (ac.fullscreen !== 0)) || (bc.floating - ac.floating);
        });
    }

    function checkClientRects(x: real, y: real): void {
        for (const client of clients) {
            if (!client)
                continue;

            const ipc = client.lastIpcObject;
            if (!ipc?.at || !ipc?.size)
                continue;

            let {
                at: [cx, cy],
                size: [cw, ch]
            } = ipc;
            cx -= screen.x;
            cy -= screen.y;
            if (cx <= x && cy <= y && cx + cw >= x && cy + ch >= y) {
                onClient = true;
                sx = cx;
                sy = cy;
                ex = cx + cw;
                ey = cy + ch;
                return;
            }
        }

        // Window mode can only select windows
        if (mode === "window")
            onClient = false;
    }

    function selectScreen(): void {
        onClient = false;
        sx = 0;
        sy = 0;
        ex = screen.width;
        ey = screen.height;
    }

    function setMode(newMode: string): void {
        Screenshot.mode = newMode;
        lassoPoints = [];

        if (newMode === "screen") {
            // Like other snipping tools, picking full screen captures straight away
            selectScreen();
            capture();
        } else {
            checkClientRects(mouseX, mouseY);
        }
    }

    function addLassoPoint(x: real, y: real): void {
        const pts = lassoPoints;
        const last = pts[pts.length - 1];
        // Skip points too close to the last one to keep the path light
        if (last && Math.abs(last.x - x) + Math.abs(last.y - y) < 3)
            return;
        lassoPoints = [...pts, Qt.point(CUtils.clamp(x, 0, width), CUtils.clamp(y, 0, height))];
    }

    function lassoBounds(): rect {
        const xs = lassoPoints.map(p => p.x);
        const ys = lassoPoints.map(p => p.y);
        const x = Math.floor(Math.min(...xs));
        const y = Math.floor(Math.min(...ys));
        return Qt.rect(x, y, Math.ceil(Math.max(...xs)) - x, Math.ceil(Math.max(...ys)) - y);
    }

    function capture(): void {
        if (capturing || done)
            return;

        done = true;
        if (loader.freeze) {
            save();
        } else {
            capturing = true;
            screencopy.visible = false;
            screencopy.active = true;
        }
    }

    function save(): void {
        const freeform = mode === "freeform";
        const tmpfile = Qt.resolvedUrl(`/tmp/caelestia-picker-${Quickshell.processId}-${Date.now()}.png`);
        // Use the target selection rather than the animated one
        const area = freeform ? lassoBounds() : Qt.rect(Math.ceil(Math.min(sx, ex)), Math.ceil(Math.min(sy, ey)), Math.floor(Math.abs(sx - ex)), Math.floor(Math.abs(sy - ey)));

        CUtils.saveItem(freeform ? freeformCapture : screencopy, tmpfile, area, path => {
            if (root.loader.clipboardOnly) {
                Quickshell.execDetached(["sh", "-c", "wl-copy --type image/png < " + path]);
                Quickshell.execDetached(["notify-send", "-a", "caelestia-cli", "-i", path, Tr.tr("Screenshot taken"), Tr.tr("Screenshot copied to clipboard")]);
            } else {
                Quickshell.execDetached(["swappy", "-f", path]);
            }
            closeAnim.start();
        });
    }

    onClientsChanged: {
        if (mode !== "screen" && mode !== "freeform")
            checkClientRects(mouseX, mouseY);
    }

    anchors.fill: parent
    opacity: 0
    hoverEnabled: true
    cursorShape: {
        if (mode === "window")
            return Qt.PointingHandCursor;
        if (mode === "screen")
            return Qt.ArrowCursor;
        return Qt.CrossCursor;
    }

    Component.onCompleted: {
        Hypr.extras.refreshOptions();

        // Break binding if frozen
        if (loader.freeze)
            clients = clients;

        opacity = 1;

        if (mode === "screen") {
            selectScreen();
            return;
        }

        const ipc = clients[0]?.lastIpcObject;
        if (ipc?.at && ipc?.size) {
            const cx = ipc.at[0] - screen.x;
            const cy = ipc.at[1] - screen.y;
            onClient = true;
            sx = cx;
            sy = cy;
            ex = cx + ipc.size[0];
            ey = cy + ipc.size[1];
        } else {
            sx = screen.width / 2 - 100;
            sy = screen.height / 2 - 100;
            ex = screen.width / 2 + 100;
            ey = screen.height / 2 + 100;
        }
    }

    onPressed: event => {
        if (mode === "freeform")
            lassoPoints = [Qt.point(event.x, event.y)];

        ssx = event.x;
        ssy = event.y;
    }

    onReleased: {
        if (closeAnim.running || done)
            return;

        if (mode === "window" && !onClient)
            return;

        // Ignore clicks and tiny scribbles
        if (mode === "freeform") {
            const bounds = lassoPoints.length > 2 ? lassoBounds() : Qt.rect(0, 0, 0, 0);
            if (bounds.width < 5 || bounds.height < 5) {
                lassoPoints = [];
                return;
            }
        }

        capture();
    }

    onPositionChanged: event => {
        const x = event.x;
        const y = event.y;

        if (mode === "freeform") {
            if (pressed)
                addLassoPoint(x, y);
        } else if (mode === "region" && pressed) {
            onClient = false;
            sx = ssx;
            sy = ssy;
            ex = x;
            ey = y;
        } else if (mode !== "screen") {
            checkClientRects(x, y);
        }
    }

    focus: true
    Keys.onEscapePressed: closeAnim.start()

    SequentialAnimation {
        id: closeAnim

        PropertyAction {
            target: root.loader
            property: "closing"
            value: true
        }
        ParallelAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.StandardLarge
            }
            Anim {
                target: root
                properties: "rsx,rsy"
                to: 0
            }
            Anim {
                target: root
                property: "sw"
                to: root.screen.width
            }
            Anim {
                target: root
                property: "sh"
                to: root.screen.height
            }
        }
        PropertyAction {
            target: root.loader
            property: "activeAsync"
            value: false
        }
    }

    Process {
        running: true
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.mode === "screen" || root.mode === "freeform")
                    return;

                const pos = JSON.parse(text);
                root.checkClientRects(pos.x - root.screen.x, pos.y - root.screen.y);
            }
        }
    }

    Loader {
        id: screencopy

        asynchronous: true
        anchors.fill: parent

        active: root.loader.freeze

        sourceComponent: ScreencopyView {
            captureSource: root.screen

            onHasContentChanged: {
                if (hasContent && !root.loader.freeze) {
                    root.capturing = false;
                    root.save();
                }
            }
        }
    }

    // Screen contents cut out to the freeform selection, only used for saving
    // Hidden with opacity as grabbing an invisible item skips its layer effects
    Item {
        id: freeformCapture

        anchors.fill: parent
        opacity: 0

        Item {
            anchors.fill: parent
            layer.enabled: root.mode === "freeform"
            layer.effect: Mask {
                maskSource: lassoMask
            }

            ShaderEffectSource {
                anchors.fill: parent
                sourceItem: root.mode === "freeform" ? screencopy.item : null
            }
        }
    }

    StyledRect {
        id: overlay

        anchors.fill: parent
        color: Colours.palette.m3scrim
        opacity: 0.5
        visible: !root.capturing

        layer.enabled: true
        layer.effect: Mask {
            maskSource: root.mode === "freeform" ? lassoMask : selectionWrapper
            maskInverted: true
        }
    }

    Item {
        id: selectionWrapper

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            id: selectionRect

            visible: root.hasSelection
            radius: root.realRounding
            x: root.rsx
            y: root.rsy
            implicitWidth: root.sw
            implicitHeight: root.sh
        }
    }

    Item {
        id: lassoMask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: "black"

                PathPolyline {
                    path: root.lassoPoints
                }
            }
        }
    }

    Rectangle {
        id: border

        visible: !root.capturing && root.hasSelection
        color: "transparent"
        radius: root.realRounding > 0 ? root.realRounding + root.realBorderWidth : 0
        border.width: root.realBorderWidth
        border.color: Colours.palette.m3primary

        x: selectionRect.x - root.realBorderWidth
        y: selectionRect.y - root.realBorderWidth
        implicitWidth: selectionRect.implicitWidth + root.realBorderWidth * 2
        implicitHeight: selectionRect.implicitHeight + root.realBorderWidth * 2

        Behavior on border.color {
            CAnim {}
        }
    }

    Shape {
        id: lassoBorder

        anchors.fill: parent
        visible: !root.capturing && root.mode === "freeform"
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 2
            strokeColor: Colours.palette.m3primary
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: root.pressed ? root.lassoPoints : [...root.lassoPoints, root.lassoPoints[0]].filter(p => p)
            }
        }
    }

    Loader {
        id: sizeLabel

        readonly property bool shown: !root.done && root.hasSelection && root.sw > 0 && root.sh > 0

        x: CUtils.clamp(root.rsx + (root.sw - width) / 2, Tokens.padding.large, root.width - width - Tokens.padding.large)
        y: {
            const below = root.rsy + root.sh + Tokens.spacing.medium;
            if (below + height < root.height - Tokens.padding.large)
                return below;
            return root.rsy + root.sh - height - Tokens.spacing.medium;
        }

        active: shown || opacity > 0
        visible: !root.capturing
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.8

        sourceComponent: StyledRect {
            implicitWidth: sizeText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: sizeText.implicitHeight + Tokens.padding.small

            radius: Tokens.rounding.full
            color: Colours.palette.m3inverseSurface

            StyledText {
                id: sizeText

                anchors.centerIn: parent
                // TRANSLATORS: selection size in pixels, %1 = width, %2 = height
                text: Tr.tr("%1 × %2").arg(Math.round(Math.abs(root.sx - root.ex))).arg(Math.round(Math.abs(root.sy - root.ey)))
                color: Colours.palette.m3inverseOnSurface
                font: Tokens.font.label.large
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    Toolbar {
        id: toolbar

        property bool shown

        anchors.horizontalCenter: parent.horizontalCenter
        y: shown && !root.done && !root.loader.closing ? Tokens.padding.extraLarge : -height - Tokens.padding.large
        visible: !root.capturing && !root.done

        mode: root.mode
        clipboardOnly: root.loader.clipboardOnly

        onModeSelected: mode => root.setMode(mode)
        onClipboardOnlyToggled: checked => root.loader.clipboardOnly = checked
        onCloseRequested: closeAnim.start()

        Component.onCompleted: shown = true

        Behavior on y {
            Anim {}
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.StandardLarge
        }
    }

    Behavior on rsx {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on rsy {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on sw {
        enabled: !root.pressed

        Anim {}
    }

    Behavior on sh {
        enabled: !root.pressed

        Anim {}
    }
}
