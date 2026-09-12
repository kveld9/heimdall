import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"

Item {
    id: page

    property var theme
    property var telemetry: null

    readonly property var health: telemetry ? telemetry.health : null
    readonly property int failedCount: health ? health.failed_units_count : 0
    readonly property var failedUnits: health ? health.failed_units : []
    readonly property var sensors: health ? health.thermal_sensors : []
    readonly property var timers: health && health.timers ? health.timers : []
    readonly property var loadavg: health && health.loadavg ? health.loadavg : ["0.00", "0.00", "0.00"]
    readonly property string uptimeStr: health && health.uptime_str ? health.uptime_str : "0m"
    readonly property int oomCount: health && health.oom_count !== undefined ? health.oom_count : 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Row 1: System Vitals & Systemd Overview
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 125
            Layout.fillHeight: false
            spacing: 10

            // System Vitals Card (Uptime, Loadavg, OOM Kills)
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "SYSTEM VITALS & KERNEL HEALTH"

                RowLayout {
                    anchors.fill: parent
                    spacing: 14

                    // Uptime
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "UPTIME"
                            font.family: theme.mainFont
                            font.pixelSize: 9
                            font.bold: true
                            color: theme.textMuted
                        }
                        Text {
                            text: page.uptimeStr
                            font.family: theme.monoFont
                            font.pixelSize: 20
                            font.bold: true
                            color: theme.textPrimary
                        }
                        Text {
                            text: "Continuous host run"
                            font.family: theme.mainFont
                            font.pixelSize: 9
                            color: theme.textMuted
                        }
                    }

                    Rectangle { width: 1; height: 40; color: theme.borderSubtle }

                    // Load Average
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text {
                            text: "LOAD AVERAGE (1m / 5m / 15m)"
                            font.family: theme.mainFont
                            font.pixelSize: 9
                            font.bold: true
                            color: theme.textMuted
                        }
                        Text {
                            text: page.loadavg[0] + " · " + page.loadavg[1] + " · " + page.loadavg[2]
                            font.family: theme.monoFont
                            font.pixelSize: 18
                            font.bold: true
                            color: theme.accentWhite
                        }
                        Text {
                            text: "Kernel runqueue pressure"
                            font.family: theme.mainFont
                            font.pixelSize: 9
                            color: theme.textMuted
                        }
                    }

                    Rectangle { width: 1; height: 40; color: theme.borderSubtle }

                    // OOM Kills
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "OOM KILLS"
                            font.family: theme.mainFont
                            font.pixelSize: 9
                            font.bold: true
                            color: theme.textMuted
                        }
                        Text {
                            text: page.oomCount.toString()
                            font.family: theme.monoFont
                            font.pixelSize: 20
                            font.bold: true
                            color: page.oomCount > 0 ? theme.accentWhite : theme.textSecondary
                        }
                        Text {
                            text: page.oomCount === 0 ? "Zero memory terminations" : "Process killed by OOM"
                            font.family: theme.mainFont
                            font.pixelSize: 9
                            color: theme.textMuted
                        }
                    }
                }
            }

            // Systemd Service State
            MetricCard {
                Layout.preferredWidth: 260
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "SYSTEMD SERVICE STATE"

                RowLayout {
                    anchors.fill: parent
                    spacing: 12

                    // Status Badge
                    Rectangle {
                        width: 80
                        height: 60
                        radius: 6
                        color: page.failedCount === 0 ? theme.bgCardHighlight : Qt.rgba(1.0, 1.0, 1.0, 0.16)
                        border.color: page.failedCount === 0 ? theme.border : theme.accentWhite

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: page.failedCount === 0 ? "OPTIMAL" : "FAILED"
                                font.family: theme.mainFont
                                font.pixelSize: 10
                                font.bold: true
                                color: theme.textPrimary
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: page.failedCount.toString()
                                font.family: theme.monoFont
                                font.pixelSize: 18
                                font.bold: true
                                color: theme.accentWhite
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: page.failedCount === 0 ? "All daemons normal" : "Failed services:"
                            font.family: theme.mainFont
                            font.pixelSize: 11
                            font.bold: true
                            color: theme.textPrimary
                        }

                        Repeater {
                            model: page.failedUnits
                            Text {
                                text: "[x] " + modelData
                                font.family: theme.monoFont
                                font.pixelSize: 10
                                color: theme.accentWhite
                                elide: Text.ElideRight
                                Layout.maximumWidth: 150
                            }
                        }

                        Text {
                            visible: page.failedCount === 0
                            text: "State: " + (page.health ? page.health.system_state : "running")
                            font.family: theme.monoFont
                            font.pixelSize: 10
                            color: theme.textMuted
                        }
                    }
                }
            }
        }

        // Row 2: Scheduled Timers & Thermal Sensor Grid
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Scheduled Timers Card
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "SCHEDULED SYSTEMD TIMERS (NEXT RUN)"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6

                    Repeater {
                        model: page.timers.slice(0, 4)

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6
                            color: theme.bgCardHighlight
                            border.color: theme.borderSubtle

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                // Indicator dot
                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: theme.accentWhite
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: modelData.unit
                                        font.family: theme.monoFont
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: theme.textPrimary
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: "-> " + modelData.activates
                                        font.family: theme.monoFont
                                        font.pixelSize: 9
                                        color: theme.textMuted
                                        elide: Text.ElideRight
                                    }
                                }

                                // Countdown badge
                                Rectangle {
                                    height: 22
                                    width: timeText.implicitWidth + 14
                                    radius: 4
                                    color: theme.bgInput
                                    border.color: theme.border

                                    Text {
                                        id: timeText
                                        anchors.centerIn: parent
                                        text: modelData.left_str
                                        font.family: theme.monoFont
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: theme.accentWhite
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        visible: page.timers.length === 0
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Text {
                            anchors.centerIn: parent
                            text: "No active system timers"
                            font.family: theme.monoFont
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                    }
                }
            }

            // Compact Thermal Grid
            MetricCard {
                Layout.preferredWidth: 320
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "HARDWARE THERMALS (/sys/class/hwmon)"

                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    rowSpacing: 6
                    columnSpacing: 6

                    Repeater {
                        model: page.sensors

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6
                            color: theme.bgCardHighlight
                            border.color: modelData.celsius >= 75 ? theme.accentWhite : theme.borderSubtle

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: modelData.label
                                        font.family: theme.monoFont
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: theme.textPrimary
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: modelData.celsius >= 75 ? "ELEVATED" : "NORMAL"
                                        font.family: theme.mainFont
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: modelData.celsius >= 75 ? theme.accentWhite : theme.textMuted
                                    }
                                }

                                Rectangle {
                                    height: 22
                                    width: 54
                                    radius: 4
                                    color: modelData.celsius >= 75 ? Qt.rgba(1.0, 1.0, 1.0, 0.16) : theme.bgInput
                                    border.color: modelData.celsius >= 75 ? theme.accentWhite : theme.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.celsius.toFixed(0) + " °C"
                                        font.family: theme.monoFont
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: theme.accentWhite
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
