import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var theme
    property var budget: null
    property int processCount: 0

    implicitWidth: 600
    implicitHeight: 115

    readonly property bool isOverBudget: budget ? ((budget.total_bytes || 0) > (budget.cap_bytes || 1073741824)) : false
    readonly property real overBytes: isOverBudget ? ((budget.total_bytes || 0) - (budget.cap_bytes || 1073741824)) : 0
    readonly property string overStr: isOverBudget ? ("+" + (theme ? theme.formatBytes(overBytes) : "0 MB") + " over budget") : ""

    readonly property real ratio: budget ? Math.min(1.0, Math.max(0.0, budget.ratio_used || 0.0)) : 0.08
    readonly property string totalStr: budget ? theme.formatBytes(budget.total_bytes) : "0 MB"
    readonly property string capStr: budget ? theme.formatBytes(budget.cap_bytes) : "1.00 GB"
    readonly property string leftStr: isOverBudget ? root.overStr : (budget ? theme.formatBytes(budget.remaining_bytes) : "0 MB")
    readonly property string warnStr: budget ? theme.formatBytes(budget.warn_bytes) : "512 MB"
    readonly property string downTodayStr: budget ? theme.formatBytes(budget.down_bytes) : "0 MB"
    readonly property string upTodayStr: budget ? theme.formatBytes(budget.up_bytes) : "0 MB"
    readonly property string peakStr: budget ? theme.formatSpeed((budget.peak_rate_bps || 0) / 1024) : "0 KB/s"

    readonly property color barColor: isOverBudget ? (theme ? theme.accentWarn : "#f59e0b") : (theme ? theme.accentWhite : "#ffffff")

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
                color: root.isOverBudget ? root.barColor : (theme ? theme.textPrimary : "#ffffff")
            }

            Text {
                text: "of " + root.capStr + " cap"
                font.family: theme ? theme.mainFont : "sans-serif"
                font.pixelSize: 12
                color: theme ? theme.textSecondary : "#d1d5db"
                Layout.alignment: Qt.AlignBaseline
            }

            // Warning Pill if Over Budget
            Rectangle {
                visible: root.isOverBudget
                height: 18
                width: warnTag.implicitWidth + 12
                radius: 4
                color: Qt.rgba(0.96, 0.62, 0.04, 0.18)
                border.color: root.barColor
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: warnTag
                    anchors.centerIn: parent
                    text: "[!] " + root.overStr.toUpperCase()
                    font.family: theme ? theme.monoFont : "monospace"
                    font.pixelSize: 9
                    font.bold: true
                    color: root.barColor
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.isOverBudget ? root.overStr : ("left " + root.leftStr)
                font.family: theme ? theme.monoFont : "monospace"
                font.pixelSize: 11
                font.bold: root.isOverBudget
                color: root.isOverBudget ? root.barColor : (theme ? theme.textMuted : "#9ca3af")
                Layout.alignment: Qt.AlignBaseline
            }
        }

        // Custom Slider Track
        Item {
            id: trackContainer
            Layout.fillWidth: true
            implicitHeight: 18

            // Background Rail
            Rectangle {
                id: rail
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 4
                radius: 2
                color: theme ? theme.bgInput : Qt.rgba(0.0, 0.0, 0.0, 0.45)
            }

            // Filled Progress
            Rectangle {
                anchors.left: rail.left
                anchors.top: rail.top
                anchors.bottom: rail.bottom
                width: rail.width * (root.isOverBudget ? 1.0 : root.ratio)
                radius: 2
                color: root.barColor
            }

            // Knob at current position
            Rectangle {
                x: rail.x + (rail.width * (root.isOverBudget ? 1.0 : root.ratio)) - width / 2
                anchors.verticalCenter: rail.verticalCenter
                width: 12
                height: 12
                radius: 6
                color: theme ? theme.bgCard : Qt.rgba(0.04, 0.04, 0.05, 0.70)
                border.color: root.barColor
                border.width: 2.5

                Rectangle {
                    anchors.centerIn: parent
                    width: 4
                    height: 4
                    radius: 2
                    color: root.barColor
                }
            }
        }

        // Sublabels row: used X MB | warn at Y MB | limit Z GB
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "used " + root.totalStr
                font.family: theme ? theme.mainFont : "sans-serif"
                font.pixelSize: 10
                color: theme ? theme.textSecondary : "#d1d5db"
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "warn at " + root.warnStr
                font.family: theme ? theme.mainFont : "sans-serif"
                font.pixelSize: 10
                color: theme ? theme.textMuted : "#9ca3af"
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "limit " + root.capStr
                font.family: theme ? theme.mainFont : "sans-serif"
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
