import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    Theme {
        id: fallbackTheme
    }

    property var theme: fallbackTheme
    property var budget: null
    property int processCount: 0

    implicitWidth: 600
    implicitHeight: 115

    readonly property real totalBytes: budget ? (budget.total_bytes || 0) : 0
    readonly property real downBytes: budget ? (budget.down_bytes || 0) : 0
    readonly property real upBytes: budget ? (budget.up_bytes || 0) : 0
    readonly property real downRatio: totalBytes > 0 ? (downBytes / totalBytes) : 0.5

    readonly property string totalStr: budget ? theme.formatBytes(totalBytes) : "0 MB"
    readonly property string downTodayStr: budget ? theme.formatBytes(downBytes) : "0 MB"
    readonly property string upTodayStr: budget ? theme.formatBytes(upBytes) : "0 MB"
    readonly property string peakStr: budget ? theme.formatSpeed((budget.peak_rate_bps || 0) / 1024) : "0 KB/s"

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // Counter & Status Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: root.totalStr
                font.family: theme ? theme.monoFont : "monospace"
                font.pixelSize: 26
                font.bold: true
                color: theme ? theme.textPrimary : "#ffffff"
            }

            Text {
                text: "transferred today (down + up)"
                font.family: theme ? theme.mainFont : "sans-serif"
                font.pixelSize: 12
                color: theme ? theme.textSecondary : "#d1d5db"
                Layout.alignment: Qt.AlignBaseline
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "peak rate " + root.peakStr
                font.family: theme ? theme.monoFont : "monospace"
                font.pixelSize: 11
                color: theme ? theme.textMuted : "#9ca3af"
                Layout.alignment: Qt.AlignBaseline
            }
        }

        // Proportional Traffic Ratio Track (Down vs Up)
        Item {
            id: trackContainer
            Layout.fillWidth: true
            implicitHeight: 14

            // Background Rail
            Rectangle {
                id: rail
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: 3
                color: theme ? theme.bgInput : Qt.rgba(0.0, 0.0, 0.0, 0.45)
            }

            // Down portion (White)
            Rectangle {
                anchors.left: rail.left
                anchors.top: rail.top
                anchors.bottom: rail.bottom
                width: rail.width * root.downRatio
                radius: 3
                color: theme ? theme.accentWhite : "#ffffff"
            }

            // Up portion (Dark Slate)
            Rectangle {
                x: rail.x + (rail.width * root.downRatio)
                anchors.top: rail.top
                anchors.bottom: rail.bottom
                anchors.right: rail.right
                radius: 3
                color: theme ? theme.accentDarkGrey : "#374151"
            }
        }

        // Sublabels row: download vs upload breakdown
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "v down " + root.downTodayStr + " (" + Math.round(root.downRatio * 100) + "%)"
                font.family: theme ? theme.monoFont : "monospace"
                font.pixelSize: 10
                color: theme ? theme.textSecondary : "#d1d5db"
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "^ up " + root.upTodayStr + " (" + Math.round((1.0 - root.downRatio) * 100) + "%)"
                font.family: theme ? theme.monoFont : "monospace"
                font.pixelSize: 10
                color: theme ? theme.textMuted : "#9ca3af"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)
            Layout.topMargin: 2
            Layout.bottomMargin: 2
        }

        // 4 Columns: Down Today | Up Today | Peak Rate | Sockets
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // Col 1: Down Today
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                Text {
                    text: "v DOWN TODAY"
                    font.family: theme ? theme.mainFont : "sans-serif"
                    font.pixelSize: 9
                    font.bold: true
                    color: theme ? theme.textMuted : "#9ca3af"
                }
                Text {
                    text: root.downTodayStr
                    font.family: theme ? theme.monoFont : "monospace"
                    font.pixelSize: 14
                    font.bold: true
                    color: theme ? theme.textPrimary : "#ffffff"
                }
            }

            // Col 2: Up Today
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                Text {
                    text: "^ UP TODAY"
                    font.family: theme ? theme.mainFont : "sans-serif"
                    font.pixelSize: 9
                    font.bold: true
                    color: theme ? theme.textMuted : "#9ca3af"
                }
                Text {
                    text: root.upTodayStr
                    font.family: theme ? theme.monoFont : "monospace"
                    font.pixelSize: 14
                    font.bold: true
                    color: theme ? theme.textPrimary : "#ffffff"
                }
            }

            // Col 3: Peak Rate
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                Text {
                    text: "PEAK RATE"
                    font.family: theme ? theme.mainFont : "sans-serif"
                    font.pixelSize: 9
                    font.bold: true
                    color: theme ? theme.textMuted : "#9ca3af"
                }
                Text {
                    text: root.peakStr
                    font.family: theme ? theme.monoFont : "monospace"
                    font.pixelSize: 14
                    font.bold: true
                    color: theme ? theme.textPrimary : "#ffffff"
                }
            }

            // Col 4: Sockets / Apps
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                Text {
                    text: "ACTIVE APPS"
                    font.family: theme ? theme.mainFont : "sans-serif"
                    font.pixelSize: 9
                    font.bold: true
                    color: theme ? theme.textMuted : "#9ca3af"
                }
                Text {
                    text: root.processCount.toString() + " apps"
                    font.family: theme ? theme.monoFont : "monospace"
                    font.pixelSize: 14
                    font.bold: true
                    color: theme ? theme.textPrimary : "#ffffff"
                }
            }
        }
    }
}
