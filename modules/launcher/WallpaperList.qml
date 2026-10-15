pragma ComponentBehavior: Bound

import "items"
import QtQuick
import Quickshell
import Caelestia.Config
import qs.components.controls
import qs.services

// M3 hero carousel: the current wallpaper is large, its neighbours shrink into
// narrower and narrower slivers that widen again as they move to the centre
PathView {
    id: root

    required property SearchBar search
    required property var screenState
    required property var panels
    required property var content

    readonly property real itemHeight: Tokens.sizes.launcher.wallpaperHeight - Tokens.padding.medium * 2
    readonly property real largeWidth: Math.round(itemHeight * 16 / 9)
    readonly property real mediumWidth: Math.round(largeWidth * 0.35)
    readonly property real smallWidth: Math.round(Tokens.sizes.launcher.wallpaperHeight * 0.28)
    readonly property real gap: Tokens.spacing.small

    readonly property int numItems: {
        const screen = (QsWindow.window as QsWindow)?.screen;
        if (!screen)
            return 0;

        // Screen width - 4x outer rounding - 2x max side thickness (cause centered)
        const barMargins = Math.max(Config.border.thickness, panels.bar.implicitWidth);
        let outerMargins = 0;
        if (panels.popouts.hasCurrent && panels.popouts.currentCenter + panels.popouts.nonAnimHeight / 2 > screen.height - content.implicitHeight - Config.border.thickness * 2)
            outerMargins = panels.popouts.nonAnimWidth;
        if ((screenState.utilities || screenState.sidebar) && panels.utilities.implicitWidth > outerMargins)
            outerMargins = panels.utilities.implicitWidth;
        const maxWidth = screen.width - Config.border.rounding * 4 - (barMargins + outerMargins) * 2;

        // Largest odd amount of items that fits
        let visible = Math.min(Config.launcher.maxWallpapers, scriptModel.values.length);
        if (visible % 2 === 0)
            visible--;
        while (visible > 1 && totalWidth(visible) > maxWidth)
            visible -= 2;

        if (visible < 1 || totalWidth(visible) > maxWidth)
            return 0;
        return visible;
    }

    // Extra item on each side so items can shrink out/grow in at the edges while scrolling
    readonly property int pathItems: Math.min(numItems + 2, count)

    // Width of the item n slots away from the centre
    function slotWidth(n: int): real {
        if (n === 0)
            return largeWidth;
        if (n === 1)
            return mediumWidth;
        return smallWidth;
    }

    // Width of all the items in a carousel showing count items
    function totalWidth(count: int): real {
        let w = 0;
        for (let i = 0; i < count; i++)
            w += slotWidth(Math.abs(i - (count - 1) / 2));
        return w + Math.max(0, count - 1) * gap;
    }

    model: ScriptModel {
        id: scriptModel

        readonly property string search: root.search.text.split(" ").slice(1).join(" ")

        values: Wallpapers.query(search)
        onValuesChanged: root.currentIndex = search ? 0 : values.findIndex(w => w.path === Wallpapers.actualCurrent)
    }

    Component.onCompleted: currentIndex = Wallpapers.list.findIndex(w => w.path === Wallpapers.actualCurrent)
    Component.onDestruction: Wallpapers.stopPreview()

    onCurrentItemChanged: {
        if (currentItem)
            Wallpapers.preview((currentItem as WallpaperItem).modelData.path);
    }

    implicitWidth: totalWidth(numItems)
    pathItemCount: numItems > 0 ? pathItems : 0
    cacheItemCount: 4
    clip: true

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange
    highlightMoveDuration: Tokens.anim.durations.expressiveDefaultSpatial

    delegate: WallpaperItem {
        screenState: root.screenState
        slots: root.numItems
        itemHeight: root.itemHeight
        largeWidth: root.largeWidth
        mediumWidth: root.mediumWidth
        smallWidth: root.smallWidth
        gap: root.gap
        slotSpacing: root.width / Math.max(1, root.pathItems)
    }

    // Straight line, items get their distance from the centre (in items) from the pos attribute
    path: Path {
        startX: 0
        startY: root.height / 2

        PathAttribute {
            name: "pos"
            value: -root.pathItems / 2
        }
        PathLine {
            x: root.width
            relativeY: 0
        }
        PathAttribute {
            name: "pos"
            value: root.pathItems / 2
        }
    }

    CustomMouseArea {
        function onWheel(event: WheelEvent): void {
            if (event.angleDelta.y > 0)
                root.decrementCurrentIndex();
            else if (event.angleDelta.y < 0)
                root.incrementCurrentIndex();
        }

        anchors.fill: parent
    }
}
