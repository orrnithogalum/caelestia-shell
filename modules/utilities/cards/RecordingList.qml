pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property var props
    required property ScreenState screenState

    readonly property bool expanded: props.recordingListExpanded
    readonly property real rowHeight: sizer.implicitHeight
    readonly property real listHeight: {
        if (!expanded)
            return 0;
        if (list.count === 0)
            return placeholder.implicitHeight + Tokens.padding.large * 2;
        return Math.min(list.count, 5) * rowHeight + Math.max(0, Math.min(list.count, 5) - 1) * list.spacing;
    }
    readonly property real nonAnimHeight: header.implicitHeight + (expanded ? listHeight + spacing : 0)

    function formatDate(baseName: string): string {
        const matches = baseName.match(/^recording_(\d{4})(\d{2})(\d{2})_(\d{2})-(\d{2})-(\d{2})/);
        if (!matches)
            return baseName;

        const date = new Date(...matches.slice(1));
        date.setMonth(date.getMonth() - 1); // Woe (months start from 0)

        const time = Qt.formatTime(date, Units.twelveHourClock ? "h:mm a" : "hh:mm");
        const startOfDay = d => new Date(d.getFullYear(), d.getMonth(), d.getDate());
        const days = Math.round((startOfDay(new Date()) - startOfDay(date)) / 86400000);

        if (days === 0)
            // TRANSLATORS: %1 = a clock time, e.g. 14:30
            return Tr.tr("Today, %1").arg(time);
        if (days === 1)
            // TRANSLATORS: %1 = a clock time, e.g. 14:30
            return Tr.tr("Yesterday, %1").arg(time);
        // TRANSLATORS: %1 = a short date, e.g. 3 Oct, %2 = a clock time, e.g. 14:30
        return Tr.tr("%1, %2").arg(date.toLocaleDateString(Qt.locale(), "d MMM")).arg(time);
    }

    spacing: Tokens.spacing.small

    StyledRect {
        id: header

        Layout.fillWidth: true
        implicitHeight: headerLayout.implicitHeight + Tokens.padding.small * 2

        radius: Tokens.rounding.full
        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)

        StateLayer {
            onClicked: root.props.recordingListExpanded = !root.props.recordingListExpanded
        }

        RowLayout {
            id: headerLayout

            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.large
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: "video_library"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Recordings")
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                animate: true
                text: list.count
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            MaterialIcon {
                text: "expand_more"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }
            }
        }
    }

    StyledListView {
        id: list

        Layout.fillWidth: true
        Layout.topMargin: root.expanded ? 0 : -root.spacing
        Layout.preferredHeight: root.listHeight
        opacity: root.expanded ? 1 : 0
        visible: Layout.preferredHeight > 0
        clip: true
        spacing: Tokens.spacing.extraSmall / 2

        model: FileSystemModel {
            path: Paths.recsdir
            nameFilters: ["recording_*.mp4"]
            sortReverse: true
        }

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: list
        }

        delegate: Item {
            id: recording

            required property FileSystemEntry modelData
            property string baseName

            anchors.left: list.contentItem.left
            anchors.right: list.contentItem.right
            implicitHeight: root.rowHeight

            Component.onCompleted: baseName = modelData.baseName

            HoverHandler {
                id: hover
            }

            StateLayer {
                radius: Tokens.rounding.full
                onClicked: {
                    root.screenState.utilities = false;
                    root.screenState.sidebar = false;
                    Quickshell.execDetached([...GlobalConfig.general.apps.playback, recording.modelData.path]);
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.small
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "play_circle"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                    fill: hover.hovered ? 1 : 0

                    Behavior on fill {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.formatDate(recording.baseName)
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }

                // Secondary actions only show on hover to keep the list tidy
                Row {
                    spacing: Tokens.spacing.extraSmall
                    opacity: hover.hovered ? 1 : 0
                    enabled: opacity > 0

                    IconButton {
                        icon: "folder"
                        type: IconButton.Text
                        onClicked: {
                            root.screenState.utilities = false;
                            root.screenState.sidebar = false;
                            Quickshell.execDetached([...GlobalConfig.general.apps.explorer, recording.modelData.path]);
                        }
                    }

                    IconButton {
                        icon: "delete_forever"
                        type: IconButton.Text
                        label.color: Colours.palette.m3error
                        stateLayer.color: Colours.palette.m3error
                        onClicked: root.props.recordingConfirmDelete = recording.modelData.path
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }

        add: Transition {
            Anim {
                type: Anim.DefaultEffects
                property: "opacity"
                from: 0
                to: 1
            }
        }

        remove: Transition {
            Anim {
                type: Anim.DefaultEffects
                property: "opacity"
                to: 0
            }
        }

        displaced: Transition {
            Anim {
                type: Anim.DefaultEffects
                property: "opacity"
                to: 1
            }
            Anim {
                property: "y"
            }
        }

        ColumnLayout {
            id: placeholder

            anchors.centerIn: parent
            spacing: Tokens.spacing.small
            opacity: list.count === 0 ? 1 : 0
            visible: opacity > 0

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "scan_delete"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("No recordings found")
                color: Colours.palette.m3outline
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Behavior on Layout.preferredHeight {
            Anim {}
        }

        Behavior on Layout.topMargin {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    // Sizes the list rows, not shown
    IconButton {
        id: sizer

        visible: false
        icon: "folder"
        type: IconButton.Text
    }
}
