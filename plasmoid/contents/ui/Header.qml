import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    property var theme
    property var telemetry: null
    property int currentPage: 0
    signal pageSelected(int pageIndex)

    implicitHeight: 52

    readonly property string iface: (telemetry && telemetry.net) ? telemetry.net.interface : "enp7s0"
    readonly property string downStr: (telemetry && telemetry.net) ? theme.formatSpeed(telemetry.net.down_rate_kb) : "0 KB/s"
    readonly property string upStr: (telemetry && telemetry.net) ? theme.formatSpeed(telemetry.net.up_rate_kb) : "0 KB/s"
    readonly property string dateStr: (telemetry && telemetry.date_display) ? telemetry.date_display : "Fri, 11 Sep"
    readonly property string timeStr: (telemetry && telemetry.time_display) ? telemetry.time_display : "18:51"

    RowLayout {
        anchors.fill: parent
        spacing: 16

        // Brand & Status
        RowLayout {
            spacing: 10

            // Pulse wave icon
            Rectangle {
                width: 22
                height: 22
                radius: 6
                color: theme.bgCardHighlight
                border.color: theme.border

                Text {
                    anchors.centerIn: parent
                    text: "∿"
                    font.pixelSize: 14
                    font.bold: true
                    color: theme.accentGreen
                }
            }

            Text {
                text: "WATCHCAT"
                font.family: theme.monoFont
                font.pixelSize: 14
                font.bold: true
                font.letterSpacing: 2.0
                color: theme.textPrimary
            }

            // Status pill
            RowLayout {
                spacing: 6
                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    color: theme.accentGreen

                    // Breathing animation
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        PropertyAnimation { to: 0.4; duration: 1200; easing.type: Easing.InOutQuad }
                        PropertyAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
                    }
                }

                Text {
                    text: "watching 24/7 · " + root.iface
                    font.family: theme.mainFont
                    font.pixelSize: 11
                    color: theme.textSecondary
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Navigation Tabs (4 Pages)
        RowLayout {
            spacing: 4

            Repeater {
                model: [
                    {index: 0, title: "Network"},
                    {index: 1, title: "Compute"},
                    {index: 2, title: "Storage"},
                    {index: 3, title: "Daemons"}
                ]

                Rectangle {
                    width: 78
                    height: 28
                    radius: 6
                    color: root.currentPage === modelData.index ? theme.bgCardHighlight : "transparent"
                    border.color: root.currentPage === modelData.index ? theme.border : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.title
                        font.family: theme.mainFont
                        font.pixelSize: 11
                        font.bold: root.currentPage === modelData.index
                        color: root.currentPage === modelData.index ? theme.accentGreen : theme.textSecondary
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

        // Live Rates & Clock
        RowLayout {
            spacing: 12

            // Down & Up badges
            RowLayout {
                spacing: 8
                Text {
                    text: "↓ " + root.downStr
                    font.family: theme.monoFont
                    font.pixelSize: 12
                    font.bold: true
                    color: theme.accentPink
                }
                Text {
                    text: "↑ " + root.upStr
                    font.family: theme.monoFont
                    font.pixelSize: 12
                    font.bold: true
                    color: theme.accentGreen
                }
            }

            Rectangle {
                width: 1
                height: 16
                color: theme.borderSubtle
            }

            // Date & Clock
            ColumnLayout {
                spacing: 1
                Text {
                    text: root.dateStr
                    font.family: theme.mainFont
                    font.pixelSize: 11
                    font.bold: true
                    color: theme.textPrimary
                    Layout.alignment: Qt.AlignRight
                }
                Text {
                    text: "refreshed " + root.timeStr
                    font.family: theme.mainFont
                    font.pixelSize: 9
                    color: theme.textMuted
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }
}
