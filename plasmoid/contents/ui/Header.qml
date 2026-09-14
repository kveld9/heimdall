import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    Theme {
        id: fallbackTheme
    }

    property var theme: fallbackTheme
    property var telemetry: null
    property bool daemonConnected: true
    property int currentPage: 0
    signal pageSelected(int pageIndex)
    signal collapseRequested()

    implicitHeight: 52

    readonly property bool isWideLayout: root.width >= 680
    readonly property string iface: (telemetry && telemetry.net && telemetry.net.interface) ? telemetry.net.interface : ""
    readonly property string downStr: (telemetry && telemetry.net) ? theme.formatSpeed(telemetry.net.down_rate_kb) : "0 KB/s"
    readonly property string upStr: (telemetry && telemetry.net) ? theme.formatSpeed(telemetry.net.up_rate_kb) : "0 KB/s"
    property var currentDate: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentDate = new Date()
    }

    readonly property string dateStr: Qt.formatDateTime(root.currentDate, "ddd, d MMM")
    readonly property string timeStr: Qt.formatDateTime(root.currentDate, "hh:mm")

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Brand & Status
        RowLayout {
            spacing: 8

            // Pulse wave icon / connection state
            Rectangle {
                width: 22
                height: 22
                radius: 6
                color: theme.bgCardHighlight
                border.color: root.daemonConnected ? theme.border : theme.borderSubtle

                Text {
                    anchors.centerIn: parent
                    text: root.daemonConnected ? "~" : "!"
                    font.pixelSize: 14
                    font.bold: true
                    color: root.daemonConnected ? theme.accentWhite : theme.accentMuted
                }
            }

            Text {
                text: "HEIMDALL"
                font.family: theme.monoFont
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 1.5
                color: theme.textPrimary
            }

            // Status pill
            RowLayout {
                spacing: 5
                visible: root.isWideLayout

                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    color: root.daemonConnected ? theme.accentWhite : theme.accentMuted
                    opacity: root.daemonConnected ? 1.0 : 0.4

                    // Breathing animation
                    SequentialAnimation on opacity {
                        running: root.daemonConnected
                        loops: Animation.Infinite
                        PropertyAnimation { to: 0.4; duration: 1200; easing.type: Easing.InOutQuad }
                        PropertyAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
                    }
                }

                Text {
                    text: root.daemonConnected ? (root.iface ? ("watching · " + root.iface) : "watching host") : "daemon offline"
                    font.family: theme.mainFont
                    font.pixelSize: 10
                    color: root.daemonConnected ? theme.textSecondary : theme.textMuted
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Navigation Tabs (4 Pages)
        RowLayout {
            spacing: 3

            Repeater {
                model: [
                    {index: 0, title: "NETWORK"},
                    {index: 1, title: "COMPUTE"},
                    {index: 2, title: "STORAGE"},
                    {index: 3, title: "DAEMONS"}
                ]

                Rectangle {
                    width: root.isWideLayout ? 70 : 62
                    height: 28
                    radius: 6
                    color: root.currentPage === modelData.index ? theme.bgCardHighlight : "transparent"
                    border.color: root.currentPage === modelData.index ? theme.border : "transparent"

                    Accessible.role: Accessible.PageTab
                    Accessible.name: modelData.title + " tab"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.title
                        font.family: theme.mainFont
                        font.pixelSize: 10
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        color: root.currentPage === modelData.index ? theme.accentWhite : theme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pageSelected(modelData.index)
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Live Rates, Clock & Collapse
        RowLayout {
            spacing: 8

            // Down & Up badges
            RowLayout {
                spacing: 6
                Text {
                    text: "v " + (root.daemonConnected ? root.downStr : "0 KB/s")
                    font.family: theme.monoFont
                    font.pixelSize: 11
                    font.bold: true
                    color: root.daemonConnected ? theme.accentSilver : theme.textDim
                }
                Text {
                    text: "^ " + (root.daemonConnected ? root.upStr : "0 KB/s")
                    font.family: theme.monoFont
                    font.pixelSize: 11
                    font.bold: true
                    color: root.daemonConnected ? theme.accentWhite : theme.textDim
                }
            }

            Rectangle {
                width: 1
                height: 16
                color: theme.borderSubtle
                visible: root.isWideLayout
            }

            // Date & Clock / Connection state
            ColumnLayout {
                spacing: 1
                visible: root.isWideLayout
                Text {
                    text: root.daemonConnected ? root.dateStr : "OFFLINE"
                    font.family: theme.mainFont
                    font.pixelSize: 10
                    font.bold: true
                    color: root.daemonConnected ? theme.textPrimary : theme.accentAlert
                    Layout.alignment: Qt.AlignRight
                }
                Text {
                    text: root.daemonConnected ? ("refreshed " + root.timeStr) : "offline"
                    font.family: theme.mainFont
                    font.pixelSize: 9
                    color: theme.textMuted
                    Layout.alignment: Qt.AlignRight
                }
            }

            // Collapse Button
            Rectangle {
                width: 76
                height: 26
                radius: 6
                color: theme.bgCardHighlight
                border.color: theme.border
                Accessible.role: Accessible.Button
                Accessible.name: "Collapse dashboard"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "^"
                        font.family: theme.monoFont
                        font.pixelSize: 11
                        font.bold: true
                        color: theme.textSecondary
                    }
                    Text {
                        text: "COLLAPSE"
                        font.family: theme.mainFont
                        font.pixelSize: 10
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        color: theme.textSecondary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.collapseRequested()
                }
            }
        }
    }
}
