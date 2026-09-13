import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "pages"

Item {
    id: fullRoot

    readonly property var theme: root.theme
    readonly property var telemetry: root.telemetry
    readonly property bool isCollapsed: root.isCollapsed

    implicitWidth: isCollapsed ? 480 : 720
    implicitHeight: isCollapsed ? 52 : 560
    Layout.minimumWidth: isCollapsed ? 420 : 620
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

        anchors.centerIn: fullRoot.isCollapsed ? parent : undefined
        anchors.fill: fullRoot.isCollapsed ? undefined : parent
        width: fullRoot.isCollapsed ? Math.min(parent.width, 480) : parent.width
        height: fullRoot.isCollapsed ? Math.min(parent.height, 52) : parent.height
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
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            visible: fullRoot.isCollapsed

            RowLayout {
                anchors.fill: parent
                spacing: 12

                // Waveform Icon
                Rectangle {
                    width: 22
                    height: 22
                    radius: 5
                    color: theme.bgCardHighlight
                    border.color: theme.border

                    Text {
                        anchors.centerIn: parent
                        text: "~"
                        font.family: theme.monoFont
                        font.pixelSize: 12
                        font.bold: true
                        color: theme.accentWhite
                    }
                }

                Text {
                    text: "HEIMDALL"
                    font.family: theme.monoFont
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.5
                    color: theme.textPrimary
                }

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
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
                    width: 1
                    height: 14
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
                    width: 84
                    height: 26
                    radius: 6
                    color: theme.bgCardHighlight
                    border.color: theme.border

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "v"
                            font.family: theme.monoFont
                            font.pixelSize: 11
                            font.bold: true
                            color: theme.textSecondary
                        }
                        Text {
                            text: "Expandir"
                            font.family: theme.mainFont
                            font.pixelSize: 11
                            font.bold: true
                            color: theme.textSecondary
                        }
                    }

                    MouseArea {
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
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            visible: !fullRoot.isCollapsed

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
