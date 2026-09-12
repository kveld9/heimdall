import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var theme
    property var budget: null
    property int processCount: 0

    implicitWidth: 600
    implicitHeight: 200

    readonly property real ratio: budget ? Math.min(1.0, Math.max(0.0, budget.ratio_used || 0.0)) : 0.08
    readonly property string totalStr: budget ? theme.formatBytes(budget.total_bytes) : "83 MB"
    readonly property string capStr: budget ? theme.formatBytes(budget.cap_bytes) : "1.00 GB"
    readonly property string leftStr: budget ? theme.formatBytes(budget.remaining_bytes) : "941 MB"
    readonly property string warnStr: budget ? theme.formatBytes(budget.warn_bytes) : "512 MB"
    readonly property string downTodayStr: budget ? theme.formatBytes(budget.down_bytes) : "45 MB"
    readonly property string upTodayStr: budget ? theme.formatBytes(budget.up_bytes) : "38 MB"
    readonly property string peakStr: budget ? theme.formatSpeed((budget.peak_rate_bps || 0) / 1024) : "500 KB/s"

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // Big Counter Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Text {
                text: root.totalStr
                font.family: theme.monoFont
                font.pixelSize: 38
                font.bold: true
                color: theme.textPrimary
            }

            Text {
                text: "of " + root.capStr + " cap  ·  " + root.ratio.toFixed(2) + " of 1.0 used"
                font.family: theme.mainFont
                font.pixelSize: 13
                color: theme.textSecondary
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 8
            }

            Item { Layout.fillWidth: true }
        }

        // Custom Slider Track
        Item {
            id: trackContainer
            Layout.fillWidth: true
            implicitHeight: 48

            // Background Rail
            Rectangle {
                id: rail
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.top
                anchors.verticalCenterOffset: 16
                height: 3
                radius: 1.5
                color: theme.border
            }

            // Filled Green Progress
            Rectangle {
                anchors.left: rail.left
                anchors.top: rail.top
                anchors.bottom: rail.bottom
                width: rail.width * root.ratio
                radius: 1.5
                color: theme.accentGreen
            }

            // Knob at current position
            Rectangle {
                x: rail.x + (rail.width * root.ratio) - width / 2
                anchors.verticalCenter: rail.verticalCenter
                width: 14
                height: 14
                radius: 7
                color: theme.bgCard
                border.color: theme.accentGreen
                border.width: 2.5

                Rectangle {
                    anchors.centerIn: parent
                    width: 4
                    height: 4
                    radius: 2
                    color: theme.accentGreen
                }
            }

            // Tick marks: 0, 0.25, 0.5, 0.75, 1.0
            Repeater {
                model: [
                    {pos: 0.0, label: "0"},
                    {pos: 0.25, label: "0.25"},
                    {pos: 0.5, label: "0.5"},
                    {pos: 0.75, label: "0.75"},
                    {pos: 1.0, label: "1.0"}
                ]

                Item {
                    x: rail.x + (rail.width * modelData.pos)
                    anchors.top: rail.bottom
                    anchors.topMargin: 3

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 1
                        height: 4
                        color: theme.border
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        font.family: theme.monoFont
                        font.pixelSize: 10
                        color: theme.textMuted
                    }
                }
            }

            // Current ratio tag below knob
            Text {
                x: rail.x + (rail.width * root.ratio) - width / 2
                anchors.top: rail.bottom
                anchors.topMargin: 18
                text: root.ratio.toFixed(2)
                font.family: theme.monoFont
                font.pixelSize: 11
                font.bold: true
                color: theme.accentGreen
                visible: root.ratio > 0.05 && root.ratio < 0.95
            }
        }

        // Sublabels row: used X MB | left Y MB | warn at Z MB
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "used " + root.totalStr
                font.family: theme.mainFont
                font.pixelSize: 11
                color: theme.textSecondary
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "left " + root.leftStr
                font.family: theme.mainFont
                font.pixelSize: 11
                color: theme.textMuted
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "warn at " + root.warnStr
                font.family: theme.mainFont
                font.pixelSize: 11
                color: theme.textMuted
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: theme.borderSubtle
            Layout.topMargin: 4
            Layout.bottomMargin: 4
        }

        // 4 Columns: Down Today | Up Today | Peak Rate | Processes
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            // Col 1: Down Today
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: "↓ DOWN TODAY"
                    font.family: theme.mainFont
                    font.pixelSize: 10
                    font.bold: true
                    color: theme.textMuted
                }
                Text {
                    text: root.downTodayStr
                    font.family: theme.monoFont
                    font.pixelSize: 17
                    font.bold: true
                    color: theme.textPrimary
                }
            }

            // Col 2: Up Today
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: "↑ UP TODAY"
                    font.family: theme.mainFont
                    font.pixelSize: 10
                    font.bold: true
                    color: theme.textMuted
                }
                Text {
                    text: root.upTodayStr
                    font.family: theme.monoFont
                    font.pixelSize: 17
                    font.bold: true
                    color: theme.textPrimary
                }
            }

            // Col 3: Peak Rate
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: "PEAK RATE"
                    font.family: theme.mainFont
                    font.pixelSize: 10
                    font.bold: true
                    color: theme.textMuted
                }
                Text {
                    text: root.peakStr
                    font.family: theme.monoFont
                    font.pixelSize: 17
                    font.bold: true
                    color: theme.textPrimary
                }
            }

            // Col 4: Processes
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: "PROCESSES"
                    font.family: theme.mainFont
                    font.pixelSize: 10
                    font.bold: true
                    color: theme.textMuted
                }
                Text {
                    text: root.processCount.toString()
                    font.family: theme.monoFont
                    font.pixelSize: 17
                    font.bold: true
                    color: theme.textPrimary
                }
            }
        }
    }
}
