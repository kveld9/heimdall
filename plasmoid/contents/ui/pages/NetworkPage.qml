import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"

Item {
    id: page

    property var theme
    property var telemetry: null

    readonly property var budget: telemetry ? telemetry.budget : null
    readonly property var weeklyList: telemetry ? telemetry.weekly : []
    readonly property var procList: telemetry && telemetry.net && telemetry.net.top_processes ? telemetry.net.top_processes : []
    readonly property var netData: telemetry ? telemetry.net : null
    readonly property real maxWeekBytes: {
        var m = 1048576;
        if (weeklyList) {
            for (var i = 0; i < weeklyList.length; i++) {
                if (weeklyList[i].total_bytes > m) m = weeklyList[i].total_bytes;
            }
        }
        return m;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // TODAY NETWORK TRAFFIC Card (Session and daily throughput)
        MetricCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 125
            cardBg: theme.bgCard
            cardBorder: theme.border
            title: "TODAY NETWORK TRAFFIC"

            BudgetSlider {
                anchors.fill: parent
                theme: page.theme
                budget: page.budget
                processCount: page.procList ? page.procList.length : 0
            }
        }

        // Live Rate Sparklines (Inbound & Outbound)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            Layout.fillHeight: false
            spacing: 10

            // Inbound (Down) Sparkline
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "INBOUND RATE (DOWN)"

                RowLayout {
                    anchors.fill: parent
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: netData ? theme.formatSpeed(netData.down_rate_kb) : "0 KB/s"
                            font.family: theme.monoFont
                            font.pixelSize: 18
                            font.bold: true
                            color: theme.accentWhite
                        }
                        Text {
                            text: "Interface: " + (netData ? netData.interface : "active")
                            font.family: theme.monoFont
                            font.pixelSize: 9
                            color: theme.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Sparkline {
                        Layout.preferredWidth: 150
                        Layout.fillHeight: true
                        values: netData ? netData.sparkline_down : []
                        strokeColor: theme.accentWhite
                        lineWidth: 1.8
                    }
                }
            }

            // Outbound (Up) Sparkline
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "OUTBOUND RATE (UP)"

                RowLayout {
                    anchors.fill: parent
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: netData ? theme.formatSpeed(netData.up_rate_kb) : "0 KB/s"
                            font.family: theme.monoFont
                            font.pixelSize: 18
                            font.bold: true
                            color: theme.accentSilver
                        }
                        Text {
                            text: "Transmitted traffic"
                            font.family: theme.mainFont
                            font.pixelSize: 9
                            color: theme.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Sparkline {
                        Layout.preferredWidth: 150
                        Layout.fillHeight: true
                        values: netData ? netData.sparkline_up : []
                        strokeColor: theme.accentGrey
                        lineWidth: 1.8
                    }
                }
            }
        }

        // Middle Row: THIS WEEK — BY DAY & TODAY SPLIT
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 170
            spacing: 10

            // THIS WEEK — BY DAY Card
            WeeklyHistoryTable {
                theme: page.theme
                weeklyList: page.weeklyList
                maxWeekBytes: page.maxWeekBytes
            }


            // TODAY SPLIT Card
            MetricCard {
                Layout.preferredWidth: 230
                Layout.minimumWidth: 200
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "TODAY SPLIT"

                DonutChart {
                    anchors.fill: parent
                    theme: page.theme
                    downPct: page.budget ? page.budget.down_pct : 55
                    upPct: page.budget ? page.budget.up_pct : 45
                    downBytesStr: page.budget ? theme.formatBytes(page.budget.down_bytes) : "0 MB"
                    upBytesStr: page.budget ? theme.formatBytes(page.budget.up_bytes) : "0 MB"
                }
            }
        }

        // TOP NETWORK APPLICATIONS (Grouped by binary name)
        MetricCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 76
            Layout.fillHeight: false
            cardBg: theme.bgCard
            cardBorder: theme.border
            title: "TOP NETWORK APPLICATIONS"

            ListView {
                id: procListView
                anchors.fill: parent
                orientation: ListView.Horizontal
                clip: true
                boundsBehavior: Flickable.DragOverBounds
                flickableDirection: Flickable.HorizontalFlick
                model: page.procList
                spacing: 8
                footer: Item { width: 16; height: 1 }

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onWheel: (wheel) => {
                        var delta = (wheel.angleDelta.y !== 0) ? wheel.angleDelta.y : wheel.angleDelta.x;
                        procListView.contentX = Math.max(0, Math.min(procListView.contentWidth - procListView.width, procListView.contentX - delta));
                    }
                }

                delegate: Rectangle {
                    height: Math.min(28, procListView.height)
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    width: pillRow.implicitWidth + 20
                    radius: 6
                    color: theme ? theme.bgCardHighlight : Qt.rgba(1.0, 1.0, 1.0, 0.08)
                    border.color: theme ? theme.border : Qt.rgba(1.0, 1.0, 1.0, 0.12)

                    RowLayout {
                        id: pillRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: modelData.name
                            font.family: theme.monoFont
                            font.pixelSize: 11
                            font.bold: true
                            color: theme ? theme.textPrimary : "#ffffff"
                        }

                        Text {
                            visible: modelData.instances > 1
                            text: "(x" + modelData.instances + ")"
                            font.family: theme.monoFont
                            font.pixelSize: 9
                            color: theme ? theme.textMuted : "#9ca3af"
                        }

                        Rectangle {
                            height: 18
                            width: rateText.implicitWidth + 10
                            radius: 4
                            color: theme ? theme.bgInput : Qt.rgba(0.0, 0.0, 0.0, 0.45)
                            border.color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)

                            Text {
                                id: rateText
                                anchors.centerIn: parent
                                text: modelData.rate_str ? modelData.rate_str : (modelData.total_io_mb > 0 ? (modelData.total_io_mb + " MB") : "0 KB/s")
                                font.family: theme.monoFont
                                font.pixelSize: 10
                                font.bold: true
                                color: theme ? theme.accentWhite : "#ffffff"
                            }
                        }
                    }
                }
            }

            Text {
                visible: page.procList.length === 0
                anchors.centerIn: parent
                text: "Monitoring active network socket I/O..."
                font.family: theme.monoFont
                font.pixelSize: 11
                color: theme.textMuted
            }
        }
    }
}
