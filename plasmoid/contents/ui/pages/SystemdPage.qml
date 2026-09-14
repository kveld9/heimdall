import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../components"

Item {
    id: page

    Theme {
        id: fallbackTheme
    }

    property var theme: fallbackTheme
    property var telemetry: null

    readonly property var health: telemetry ? telemetry.health : null
    readonly property int failedCount: health ? health.failed_units_count : 0
    readonly property var failedUnits: health ? health.failed_units : []
    readonly property var sensors: health ? health.thermal_sensors : []
    readonly property var timers: health && health.timers ? health.timers : []
    readonly property var loadavg: health && health.loadavg ? health.loadavg : ["0.00", "0.00", "0.00"]
    readonly property int cpuCores: (health && health.cpu_cores > 0) ? health.cpu_cores : 1
    readonly property string uptimeStr: health && health.uptime_str ? health.uptime_str : "0m"
    readonly property int oomCount: health && health.oom_count !== undefined ? health.oom_count : 0

    // Loadavg ratio relative to logical CPU threads
    readonly property real load1m: parseFloat(loadavg[0]) || 0.0
    readonly property real loadRatio: cpuCores > 0 ? (load1m / cpuCores) : 0.0
    readonly property color loadColor: theme ? theme.accentWhite : "#ffffff"

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
                theme: page.theme
                Layout.fillWidth: true
                Layout.preferredHeight: 210
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
                theme: page.theme
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "SCHEDULED SYSTEMD TIMERS (NEXT RUN)"

                SystemdTimersTable {
                    anchors.fill: parent
                    theme: page.theme
                    model: page.timers
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
            SystemdStateCard {
                theme: page.theme
                failedCount: page.failedCount
                failedUnits: page.failedUnits
                systemState: page.health ? page.health.system_state : "running"
            }

            // 2. HARDWARE THERMALS (Expanded Grid)
            MetricCard {
                theme: page.theme
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "HARDWARE THERMALS (/sys/class/hwmon)"

                HardwareThermalsTable {
                    anchors.fill: parent
                    theme: page.theme
                    model: page.sensors
                    sparkline: page.health && page.health.sparkline_temp ? page.health.sparkline_temp : []
                    fans: page.health && page.health.fan_sensors ? page.health.fan_sensors : []
                    voltages: page.health && page.health.voltage_sensors ? page.health.voltage_sensors : []
                }
            }
        }
    }
}
