import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "pages"

Item {
    id: fullRoot

    readonly property var theme: root.theme
    readonly property var telemetry: root.telemetry
    readonly property bool isCollapsed: root.isCollapsed

    implicitWidth: isCollapsed ? 520 : 720
    implicitHeight: isCollapsed ? 52 : 560
    Layout.minimumWidth: isCollapsed ? 460 : 620
    Layout.minimumHeight: isCollapsed ? 52 : 500
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    Behavior on implicitHeight {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }
    Behavior on implicitWidth {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    // Outer visual card: strictly constrained and centered when collapsed
    Rectangle {
        id: card
        color: theme.bgPrimary
        border.color: theme.border
        border.width: 1
        clip: true

        anchors.centerIn: parent
        width: fullRoot.isCollapsed ? Math.min(parent.width > 0 ? parent.width : 520, 520) : (parent.width > 0 ? parent.width : 720)
        height: fullRoot.isCollapsed ? Math.min(parent.height > 0 ? parent.height : 52, 52) : (parent.height > 0 ? parent.height : 560)
        radius: fullRoot.isCollapsed ? 26 : 16

        Behavior on width {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on radius {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        // Collapsed Capsule View
        Item {
            id: capsuleView
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            opacity: fullRoot.isCollapsed ? 1.0 : 0.0
            visible: opacity > 0
            enabled: fullRoot.isCollapsed

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 10

                // Waveform Icon
                Rectangle {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 5
                    color: theme.bgCardHighlight
                    border.color: theme.border

                    Text {
                        anchors.centerIn: parent
                        text: "~"
                        font.family: theme.monoFont
                        font.pixelSize: 11
                        font.bold: true
                        color: theme.accentWhite
                    }
                }

                Text {
                    text: "HEIMDALL"
                    font.family: theme.monoFont
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.0
                    color: theme.textPrimary
                }

                Rectangle {
                    Layout.preferredWidth: 5
                    Layout.preferredHeight: 5
                    radius: 2.5
                    color: theme.accentWhite
                }

                // Live Rates
                Text {
                    text: "v " + ((telemetry && telemetry.net) ? theme.formatSpeed(telemetry.net.down_rate_kb) : "0 KB/s")
                    font.family: theme.monoFont
                    font.pixelSize: 11
                    font.bold: true
                    color: theme.accentSilver
                }

                Text {
                    text: "^ " + ((telemetry && telemetry.net) ? theme.formatSpeed(telemetry.net.up_rate_kb) : "0 KB/s")
                    font.family: theme.monoFont
                    font.pixelSize: 11
                    font.bold: true
                    color: theme.accentWhite
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 14
                    color: theme.borderSubtle
                }

                // Today Transferred
                Text {
                    text: (telemetry && telemetry.budget) ? ("Today: " + theme.formatBytes(telemetry.budget.total_bytes)) : "Today: 0 MB"
                    font.family: theme.monoFont
                    font.pixelSize: 11
                    color: theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                // Expand Button
                Rectangle {
                    id: expandBtn
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    implicitWidth: expandRow.implicitWidth + 18
                    implicitHeight: 24
                    radius: 6
                    color: btnArea.containsMouse ? theme.bgCardHighlight : theme.bgCard
                    border.color: btnArea.containsMouse ? theme.accentWhite : theme.border

                    Row {
                        id: expandRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "v"
                            font.family: theme.monoFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "EXPAND"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            font.capitalization: Font.AllUppercase
                            color: theme.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: btnArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.isCollapsed = false
                    }
                }
            }
        }

        // Expanded Full View
        ColumnLayout {
            id: expandedView
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            opacity: fullRoot.isCollapsed ? 0.0 : 1.0
            visible: opacity > 0
            enabled: !fullRoot.isCollapsed

            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            // Header with Logo, live rates, tabs, and collapse button
            Header {
                id: header
                Layout.fillWidth: true
                theme: root.theme
                telemetry: root.telemetry
                currentPage: stack.currentIndex
                onPageSelected: function(idx) {
                    stack.currentIndex = idx;
                }
                onCollapseRequested: {
                    root.isCollapsed = true;
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: theme.borderSubtle
            }

            // 4 Multi-page Stack
            StackLayout {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: 0

                NetworkPage {
                    theme: root.theme
                    telemetry: root.telemetry
                }

                ComputePage {
                    theme: root.theme
                    telemetry: root.telemetry
                }

                StoragePage {
                    theme: root.theme
                    telemetry: root.telemetry
                }

                SystemdPage {
                    theme: root.theme
                    telemetry: root.telemetry
                }
            }
        }
    }
}
