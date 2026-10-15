import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import qs.components
import qs.components.images
import qs.services

Item {
    id: root

    required property int index
    required property FileSystemEntry modelData
    required property ScreenState screenState

    required property int slots
    required property real itemHeight
    required property real largeWidth
    required property real mediumWidth
    required property real smallWidth
    required property real gap
    required property real slotSpacing

    // Distance from the centre of the carousel, in items (0 = current)
    readonly property real pos: PathView.pos ?? 0 // qmllint disable missing-property
    readonly property real dist: Math.abs(pos)
    readonly property int edge: Math.floor((slots - 1) / 2)
    readonly property real focusAmount: Math.max(0, 1 - dist * 2)
    readonly property bool isCurrentWallpaper: modelData.path === Wallpapers.actualCurrent

    readonly property real itemWidth: {
        if (dist > edge) // Leaving or entering the carousel
            return slotWidth(edge) * Math.max(0, 1 - (dist - edge) * 2);

        const lo = Math.floor(dist);
        return slotWidth(lo) + (slotWidth(Math.ceil(dist)) - slotWidth(lo)) * (dist - lo);
    }

    readonly property real centre: {
        if (dist > edge) {
            // Shrink against the next item in so the gap stays the same
            const f = Math.min(1, (dist - edge) * 2);
            return slotCentre(edge) - slotWidth(edge) / 2 + f * (slotWidth(edge) + gap) + itemWidth / 2;
        }

        const lo = Math.floor(dist);
        return slotCentre(lo) + (slotCentre(Math.ceil(dist)) - slotCentre(lo)) * (dist - lo);
    }

    function slotWidth(n: int): real {
        if (n === 0)
            return largeWidth;
        if (n === 1)
            return mediumWidth;
        return smallWidth;
    }

    // Distance from the centre of the carousel to the centre of the item n slots away
    function slotCentre(n: int): real {
        if (n === 0)
            return 0;

        let c = largeWidth / 2;
        for (let i = 1; i < n; i++)
            c += gap + slotWidth(i);
        return c + gap + slotWidth(n) / 2;
    }

    // The path spaces items evenly, so move the card to where it should be in the carousel
    implicitWidth: 0
    implicitHeight: itemHeight
    visible: itemWidth > 0.5

    StyledClippingRect {
        id: card

        x: (root.pos < 0 ? -root.centre : root.centre) - root.pos * root.slotSpacing - width / 2
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: root.itemWidth
        implicitHeight: root.itemHeight

        radius: Math.min(Tokens.rounding.extraLarge, width / 2)
        color: Colours.tPalette.m3surfaceContainer

        MaterialIcon {
            anchors.centerIn: parent
            text: "image"
            color: Colours.tPalette.m3outline
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.DemiBold).build()
            opacity: root.focusAmount
        }

        // Full size image, the card masks it as it shrinks
        CachingImage {
            x: (card.width - width) / 2
            width: root.largeWidth
            height: root.itemHeight
            path: root.modelData.path
            smooth: !root.PathView.view.moving
        }

        // Scrim so the name is readable on any wallpaper
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            implicitHeight: parent.height * 0.45
            opacity: root.focusAmount

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(Colours.palette.m3scrim, 0.6)
                }
            }
        }

        StyledText {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Tokens.padding.large

            opacity: root.focusAmount
            text: root.modelData.relativePath
            color: "white"
            font: Tokens.font.title.small
            elide: Text.ElideRight
        }

        StyledRect {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Math.min(Tokens.padding.medium, (card.width - width) / 2)

            implicitWidth: currentRow.implicitWidth + Tokens.padding.small * 2
            implicitHeight: currentRow.implicitHeight + Tokens.padding.extraSmall * 2

            radius: Tokens.rounding.full
            color: Colours.palette.m3primary
            opacity: root.isCurrentWallpaper && card.width > implicitWidth ? 1 : 0
            visible: opacity > 0

            Row {
                id: currentRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "check"
                    color: Colours.palette.m3onPrimary
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.focusAmount > 0.5
                    // TRANSLATORS: marks the wallpaper that is currently set
                    text: Tr.trCtx("Current", "wallpaper")
                    color: Colours.palette.m3onPrimary
                    font: Tokens.font.label.medium
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        StateLayer {
            radius: card.radius
            onClicked: {
                // Bring other wallpapers to the centre first, set the centred one
                if (!root.PathView.isCurrentItem) {
                    root.PathView.view.currentIndex = root.index;
                    return;
                }

                Wallpapers.setWallpaper(root.modelData.path);
                root.screenState.launcher = false;
            }
        }
    }
}
