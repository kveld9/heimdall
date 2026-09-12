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
    readonly property real colDayWidth: 72
    readonly property real colDateWidth: 52
    readonly property real colDownWidth: 76
    readonly property real colUpWidth: 76
    readonly property real colTotalWidth: 104
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
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "THIS WEEK - BY DAY"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    // Table Header with high contrast
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        Layout.rightMargin: 6
                        spacing: 8

                        Text {
                            text: "DAY"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textSecondary
                            Layout.preferredWidth: page.colDayWidth
                        }
                        Text {
                            text: "DATE"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textSecondary
                            Layout.preferredWidth: page.colDateWidth
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "DOWN"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textSecondary
                            Layout.preferredWidth: page.colDownWidth
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            text: "UP"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textSecondary
                            Layout.preferredWidth: page.colUpWidth
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            text: "TOTAL"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textSecondary
                            Layout.preferredWidth: page.colTotalWidth
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: theme.borderSubtle
                    }

                    // Table Rows
                    ListView {
                        id: weekListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: page.weeklyList
                        spacing: 2

                        delegate: Rectangle {
                            width: weekListView.width
                            height: 20
                            radius: 4
                            color: modelData.is_today ? theme.bgCardHighlight : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 8

                                Text {
                                    text: modelData.day
                                    font.family: theme.mainFont
                                    font.pixelSize: 11
                                    font.bold: modelData.is_today
                                    color: modelData.is_today ? theme.textPrimary : theme.textSecondary
                                    Layout.preferredWidth: page.colDayWidth
                                }

                                Text {
                                    text: modelData.date
                                    font.family: theme.mainFont
                                    font.pixelSize: 10
                                    color: theme.textMuted
                                    Layout.preferredWidth: page.colDateWidth
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: theme.formatBytes(modelData.down_bytes)
                                    font.family: theme.monoFont
                                    font.pixelSize: 11
                                    color: theme.textSecondary
                                    Layout.preferredWidth: page.colDownWidth
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    text: theme.formatBytes(modelData.up_bytes)
                                    font.family: theme.monoFont
                                    font.pixelSize: 11
                                    color: theme.textSecondary
                                    Layout.preferredWidth: page.colUpWidth
                                    horizontalAlignment: Text.AlignRight
                                }

                                RowLayout {
                                    Layout.preferredWidth: page.colTotalWidth
                                    spacing: 6

                                    Text {
                                        text: theme.formatBytes(modelData.total_bytes)
                                        font.family: theme.monoFont
                                        font.pixelSize: 11
                                        font.bold: modelData.is_today
                                        color: modelData.is_today ? theme.accentWhite : theme.textSecondary
                                        horizontalAlignment: Text.AlignRight
                                        Layout.fillWidth: true
                                    }

                                    // Mini bar indicator
                                    Rectangle {
                                        width: 28
                                        height: 4
                                        radius: 2
                                        color: theme.bgInput
                                        Layout.alignment: Qt.AlignVCenter

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: Math.min(parent.width, Math.max(2, parent.width * (modelData.total_bytes / page.maxWeekBytes)))
                                            radius: 2
                                            color: modelData.is_today ? theme.accentWhite : theme.accentGrey
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // TODAY SPLIT Card
            MetricCard {
                Layout.preferredWidth: 260
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
                model: page.procList
                spacing: 8

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
                            color: "#ffffff"
                        }

                        Text {
                            visible: modelData.instances > 1
                            text: "(x" + modelData.instances + ")"
                            font.family: theme.monoFont
                            font.pixelSize: 9
                            color: "#9ca3af"
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
                                color: "#ffffff"
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
