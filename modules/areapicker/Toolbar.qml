pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

StyledRect {
    id: root

    required property string mode
    property bool clipboardOnly

    signal modeSelected(mode: string)
    signal clipboardOnlyToggled(checked: bool)
    signal closeRequested

    implicitWidth: layout.implicitWidth + Tokens.padding.small * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.small * 2

    radius: Tokens.rounding.full
    color: Colours.palette.m3surfaceContainer

    Elevation {
        anchors.fill: parent
        radius: parent.radius
        z: -1
        level: 3
    }

    // Swallow clicks on the toolbar background so they don't start a selection
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
    }

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        Row {
            spacing: Tokens.spacing.extraSmall / 2

            ModeButton {
                mode: "region"
                icon: "screenshot_region"
                label: Tr.trCtx("Rectangle", "screenshot mode")
                first: true
            }

            ModeButton {
                mode: "window"
                icon: "select_window"
                label: Tr.trCtx("Window", "screenshot mode")
            }

            ModeButton {
                mode: "screen"
                icon: "fullscreen"
                label: Tr.trCtx("Full screen", "screenshot mode")
            }

            ModeButton {
                mode: "freeform"
                icon: "gesture"
                label: Tr.trCtx("Freeform", "screenshot mode")
                last: true
            }
        }

        StyledRect {
            Layout.leftMargin: Tokens.spacing.extraSmall
            Layout.rightMargin: Tokens.spacing.extraSmall
            implicitWidth: 1
            implicitHeight: Tokens.font.icon.medium.pointSize * 1.5
            color: Colours.palette.m3outlineVariant
        }

        IconButton {
            icon: "content_paste"
            type: IconButton.Tonal
            inactiveColour: Colours.tPalette.m3surfaceContainerHighest
            inactiveOnColour: Colours.palette.m3onSurfaceVariant
            isToggle: true
            checked: root.clipboardOnly
            onClicked: root.clipboardOnlyToggled(internalChecked)
        }

        IconButton {
            icon: "close"
            type: IconButton.Text
            onClicked: root.closeRequested()
        }
    }

    component ModeButton: StyledRect {
        id: modeButton

        required property string mode
        required property string icon
        required property string label
        property bool first
        property bool last

        readonly property bool active: root.mode === mode
        readonly property real outerRadius: height / 2
        property real innerRadius: active ? height / 2 : Tokens.rounding.small

        implicitWidth: active ? modeIcon.implicitWidth + labelMetrics.advanceWidth + Tokens.spacing.small + Tokens.padding.large * 2 : implicitHeight
        implicitHeight: modeIcon.implicitHeight + Tokens.padding.small * 2

        color: active ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHighest
        topLeftRadius: first ? outerRadius : innerRadius
        bottomLeftRadius: first ? outerRadius : innerRadius
        topRightRadius: last ? outerRadius : innerRadius
        bottomRightRadius: last ? outerRadius : innerRadius
        clip: true

        StateLayer {
            color: modeButton.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            onClicked: root.modeSelected(modeButton.mode)
        }

        TextMetrics {
            id: labelMetrics

            text: modeButton.label
            font: Tokens.font.label.large
        }

        Row {
            anchors.centerIn: parent
            spacing: modeButton.active ? Tokens.spacing.small : 0

            MaterialIcon {
                id: modeIcon

                anchors.verticalCenter: parent.verticalCenter
                text: modeButton.icon
                color: modeButton.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                fill: modeButton.active ? 1 : 0

                Behavior on fill {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: modeButton.active ? Math.ceil(labelMetrics.advanceWidth) + 1 : 0
                text: labelMetrics.text
                color: Colours.palette.m3onPrimary
                font: labelMetrics.font
                opacity: modeButton.active ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Behavior on spacing {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        Behavior on implicitWidth {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Behavior on innerRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
