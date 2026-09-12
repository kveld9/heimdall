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
    readonly property int cpuCores: health && health.cpu_cores ? health.cpu_cores : 16
    readonly property string uptimeStr: health && health.uptime_str ? health.uptime_str : "0m"
    readonly property int oomCount: health && health.oom_count !== undefined ? health.oom_count : 0

    // Loadavg ratio relative to logical CPU threads
    readonly property real load1m: parseFloat(loadavg[0]) || 0.0
    readonly property real loadRatio: cpuCores > 0 ? (load1m / cpuCores) : 0.0
    readonly property color loadColor: loadRatio >= 1.0 ? (theme ? theme.accentAlert : "#ef4444") : (loadRatio >= 0.75 ? (theme ? theme.accentWarn : "#f59e0b") : (theme ? theme.accentWhite : "#ffffff"))

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // ==========================================
        // LEFT COLUMN: Vitals + Scheduled Timers
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // 1. SYSTEM VITALS & KERNEL HEALTH
            MetricCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "SYSTEM VITALS & KERNEL HEALTH"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    // Top subrow: UPTIME & OOM KILLS
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // Uptime
                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
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

                        Rectangle { width: 1; height: 36; color: theme.borderSubtle }

                        // OOM Kills
                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Text {
                                text: "OOM TERMINATIONS"
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
                                color: page.oomCount > 0 ? theme.accentAlert : theme.textSecondary
                            }
                            Text {
                                text: page.oomCount === 0 ? "Zero memory kills" : "Process killed by OOM"
                                font.family: theme.mainFont
                                font.pixelSize: 9
                                color: page.oomCount > 0 ? theme.accentAlert : theme.textMuted
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: theme.borderSubtle }

                    // Bottom subrow: LOAD AVERAGE with CPU cores capacity bar
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "LOAD AVERAGE (1m · 5m · 15m)"
                                font.family: theme.mainFont
                                font.pixelSize: 9
                                font.bold: true
                                color: theme.textMuted
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: ((page.loadRatio * 100).toFixed(0)) + "% of " + page.cpuCores + " threads"
                                font.family: theme.monoFont
                                font.pixelSize: 10
                                font.bold: true
                                color: page.loadColor
                            }
                        }

                        Text {
                            text: page.loadavg[0] + "  ·  " + page.loadavg[1] + "  ·  " + page.loadavg[2]
                            font.family: theme.monoFont
                            font.pixelSize: 18
                            font.bold: true
                            color: page.loadColor
                        }

                        // Load Capacity Gauge Bar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 5
                            radius: 2.5
                            color: theme.bgInput

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * Math.min(1.0, Math.max(0.04, page.loadRatio))
                                radius: 2.5
                                color: page.loadColor
                            }
                        }
                    }
                }
            }

            // 2. SCHEDULED SYSTEMD TIMERS
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
                            text: "Scanning scheduled timers..."
                            font.family: theme.monoFont
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                    }
                }
            }
        }

        // ==========================================
        // RIGHT COLUMN: Systemd State + Expanded Thermals
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // 1. SYSTEMD SERVICE STATE
            MetricCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "SYSTEMD SERVICE STATE"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // Status Badge
                        Rectangle {
                            width: 80
                            height: 54
                            radius: 6
                            color: page.failedCount === 0 ? theme.bgCardHighlight : Qt.rgba(0.94, 0.27, 0.27, 0.18)
                            border.color: page.failedCount === 0 ? theme.border : theme.accentAlert

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    text: page.failedCount === 0 ? "OPTIMAL" : "FAILED"
                                    font.family: theme.mainFont
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: page.failedCount === 0 ? theme.textPrimary : theme.accentAlert
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: page.failedCount.toString()
                                    font.family: theme.monoFont
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: page.failedCount === 0 ? theme.accentWhite : theme.accentAlert
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: page.failedCount === 0 ? "All system daemons normal" : "Failed services:"
                                font.family: theme.mainFont
                                font.pixelSize: 11
                                font.bold: true
                                color: theme.textPrimary
                            }

                            Text {
                                text: "System State: " + (page.health ? page.health.system_state : "running")
                                font.family: theme.monoFont
                                font.pixelSize: 10
                                color: theme.textSecondary
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: theme.borderSubtle }

                    // Failed units list or Healthy verification
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 3

                        Repeater {
                            model: page.failedUnits
                            RowLayout {
                                spacing: 6
                                Rectangle { width: 6; height: 6; radius: 3; color: theme.accentAlert }
                                Text {
                                    text: modelData
                                    font.family: theme.monoFont
                                    font.pixelSize: 10
                                    color: theme.accentAlert
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Text {
                            visible: page.failedCount === 0
                            text: "[v] Core targets, sockets, and mounts active"
                            font.family: theme.monoFont
                            font.pixelSize: 10
                            color: theme.textMuted
                        }

                        Text {
                            visible: page.failedCount === 0
                            text: "[*] Zero failed units in current systemd transaction"
                            font.family: theme.monoFont
                            font.pixelSize: 9
                            color: theme.textMuted
                        }
                    }
                }
            }

            // 2. HARDWARE THERMALS (Expanded Grid)
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "HARDWARE THERMALS (/sys/class/hwmon)"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Repeater {
                        model: page.sensors

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6
                            color: theme.bgCardHighlight
                            border.color: modelData.celsius >= 80 ? theme.accentAlert : (modelData.celsius >= 65 ? theme.accentWarn : theme.borderSubtle)

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true

                                    ColumnLayout {
                                        spacing: 1
                                        Text {
                                            text: modelData.label
                                            font.family: theme.monoFont
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: theme.textPrimary
                                        }
                                        Text {
                                            text: modelData.celsius >= 80 ? "HOT" : (modelData.celsius >= 65 ? "WARM" : "OPTIMAL")
                                            font.family: theme.mainFont
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: modelData.celsius >= 80 ? theme.accentAlert : (modelData.celsius >= 65 ? theme.accentWarn : theme.textMuted)
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        height: 22
                                        width: 58
                                        radius: 4
                                        color: modelData.celsius >= 80 ? Qt.rgba(0.94, 0.27, 0.27, 0.2) : theme.bgInput
                                        border.color: modelData.celsius >= 80 ? theme.accentAlert : theme.border

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.celsius.toFixed(1) + " °C"
                                            font.family: theme.monoFont
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: modelData.celsius >= 80 ? theme.accentAlert : theme.accentWhite
                                        }
                                    }
                                }

                                // Thermal Progress Rail
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 4
                                    radius: 2
                                    color: theme.bgInput

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: parent.width * Math.min(1.0, Math.max(0.05, modelData.celsius / 100.0))
                                        radius: 2
                                        color: modelData.celsius >= 80 ? theme.accentAlert : (modelData.celsius >= 65 ? theme.accentWarn : theme.accentWhite)
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        visible: page.sensors.length === 0
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Text {
                            anchors.centerIn: parent
                            text: "Scanning thermal sensors..."
                            font.family: theme.monoFont
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                    }
                }
            }
        }
    }
}
