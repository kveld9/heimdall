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

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // DAY BUDGET Card (Main identity of Heimdall)
        MetricCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 125
            cardBg: theme.bgCard
            cardBorder: theme.border
            title: "DAY BUDGET"

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
                        spacing: 8

                        Text {
                            text: "DAY"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textSecondary
                            Layout.preferredWidth: 70
                        }
                        Text {
                            text: "DATE"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textSecondary
                            Layout.preferredWidth: 55
                        }
                        Text {
                            text: "DOWN"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textSecondary
                            Layout.preferredWidth: 65
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            text: "UP"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textSecondary
                            Layout.preferredWidth: 65
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            text: "TOTAL"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textSecondary
                            Layout.fillWidth: true
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
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 8

                                Text {
                                    text: modelData.day
                                    font.family: theme.mainFont
                                    font.pixelSize: 11
                                    font.bold: modelData.is_today
                                    color: modelData.is_today ? theme.textPrimary : theme.textSecondary
                                    Layout.preferredWidth: 70
                                }

                                Text {
                                    text: modelData.date
                                    font.family: theme.mainFont
                                    font.pixelSize: 10
                                    color: theme.textMuted
                                    Layout.preferredWidth: 55
                                }

                                Text {
                                    text: theme.formatBytes(modelData.down_bytes)
                                    font.family: theme.monoFont
                                    font.pixelSize: 11
                                    color: theme.textSecondary
                                    Layout.preferredWidth: 65
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    text: theme.formatBytes(modelData.up_bytes)
                                    font.family: theme.monoFont
                                    font.pixelSize: 11
                                    color: theme.textSecondary
                                    Layout.preferredWidth: 65
                                    horizontalAlignment: Text.AlignRight
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignRight
                                    spacing: 6

                                    Text {
                                        text: theme.formatBytes(modelData.total_bytes)
                                        font.family: theme.monoFont
                                        font.pixelSize: 11
                                        font.bold: modelData.is_today
                                        color: modelData.is_today ? theme.accentWhite : theme.textSecondary
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    // Mini bar indicator
                                    Rectangle {
                                        width: 28
                                        height: 4
                                        radius: 2
                                        color: theme.bgInput

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: Math.min(parent.width, Math.max(2, parent.width * (modelData.total_bytes / (page.budget ? page.budget.cap_bytes : 1073741824))))
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
            Layout.preferredHeight: 74
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
                    width: 155
                    height: procListView.height
                    radius: 6
                    color: theme.bgCardHighlight
                    border.color: theme.borderSubtle

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: modelData.name
                                font.family: theme.monoFont
                                font.pixelSize: 11
                                font.bold: true
                                color: theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: modelData.instances > 1 ? ("(x" + modelData.instances + ")") : ""
                                font.family: theme.monoFont
                                font.pixelSize: 9
                                color: theme.textMuted
                            }
                        }

                        Item { Layout.fillHeight: true }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "R: " + (modelData.read_mb >= 1024 ? (modelData.read_mb / 1024.0).toFixed(1) + " GB" : modelData.read_mb.toFixed(0) + " MB")
                                font.family: theme.monoFont
                                font.pixelSize: 10
                                color: theme.textSecondary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "W: " + (modelData.write_mb >= 1024 ? (modelData.write_mb / 1024.0).toFixed(1) + " GB" : modelData.write_mb.toFixed(0) + " MB")
                                font.family: theme.monoFont
                                font.pixelSize: 10
                                color: theme.accentWhite
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
