import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "pages"

Item {
    id: fullRoot

    Theme {
        id: fallbackTheme
    }

    readonly property var theme: (typeof root !== "undefined" && root && root.theme) ? root.theme : fallbackTheme
    readonly property var telemetry: (typeof root !== "undefined" && root && root.telemetry) ? root.telemetry : null
    readonly property bool isCollapsed: (typeof root !== "undefined" && root) ? root.isCollapsed : false
    readonly property bool daemonConnected: (typeof root !== "undefined" && root) ? root.daemonConnected : false

    implicitWidth: isCollapsed ? theme.capsuleWidth : theme.expandedWidth
    implicitHeight: isCollapsed ? theme.capsuleHeight : theme.expandedHeight
    Layout.minimumWidth: isCollapsed ? theme.minCapsuleWidth : theme.minExpandedWidth
    Layout.minimumHeight: isCollapsed ? theme.capsuleHeight : theme.minExpandedHeight
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
        width: fullRoot.isCollapsed ? Math.min(parent.width > 0 ? parent.width : theme.capsuleWidth, theme.capsuleWidth) : (parent.width > 0 ? parent.width : theme.expandedWidth)
        height: fullRoot.isCollapsed ? Math.min(parent.height > 0 ? parent.height : theme.capsuleHeight, theme.capsuleHeight) : (parent.height > 0 ? parent.height : theme.expandedHeight)
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

                // Today Transferred / Offline state
                Text {
                    text: !fullRoot.daemonConnected ? "DAEMON OFFLINE" : ((telemetry && telemetry.budget) ? ("Today: " + theme.formatBytes(telemetry.budget.total_bytes)) : "Today: 0 MB")
                    font.family: theme.monoFont
                    font.pixelSize: 11
                    font.bold: !fullRoot.daemonConnected
                    color: !fullRoot.daemonConnected ? theme.accentSilver : theme.textSecondary
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
                    Accessible.role: Accessible.Button
                    Accessible.name: "Expand dashboard"

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
                        onClicked: {
                            if (typeof root !== "undefined" && root) {
                                root.isCollapsed = false;
                            }
                        }
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
                theme: fullRoot.theme
                telemetry: fullRoot.telemetry
                daemonConnected: fullRoot.daemonConnected
                currentPage: stack.currentIndex
                onPageSelected: function(idx) {
                    stack.currentIndex = idx;
                }
                onCollapseRequested: {
                    if (typeof root !== "undefined" && root) {
                        root.isCollapsed = true;
                    }
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
                    theme: fullRoot.theme
                    telemetry: fullRoot.telemetry
                }

                ComputePage {
                    theme: fullRoot.theme
                    telemetry: fullRoot.telemetry
                }

                StoragePage {
                    theme: fullRoot.theme
                    telemetry: fullRoot.telemetry
                }

                SystemdPage {
                    theme: fullRoot.theme
                    telemetry: fullRoot.telemetry
                }
            }
        }
    }
}
