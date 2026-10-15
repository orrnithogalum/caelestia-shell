import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    readonly property real nonAnimHeight: implicitHeight

    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + Tokens.padding.large

            radius: Tokens.rounding.full
            color: IdleInhibitor.enabled ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: "coffee"
                color: IdleInhibitor.enabled ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: Tr.trCtx("Keep awake", "idle inhibitor")
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true

                text: {
                    if (IdleInhibitor.clamshell)
                        return Tr.trCtx("Preventing sleep (clamshell mode)", "idle inhibitor");
                    if (IdleInhibitor.enabled)
                        // TRANSLATORS: %1 = a clock time, e.g. 14:30
                        return Tr.tr("Active since %1").arg(Qt.formatTime(IdleInhibitor.enabledSince, Units.twelveHourClock ? "hh:mm a" : "hh:mm"));
                    return Tr.trCtx("Normal power management", "idle inhibitor");
                }

                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
                animate: true
            }
        }

        StyledSwitch {
            checked: IdleInhibitor.enabled
            onToggled: IdleInhibitor.enabled = checked
        }
    }
}
