import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"

Item {
    id: page

    property var theme
    property var telemetry: null

    readonly property var compute: telemetry ? telemetry.compute : null
    readonly property var zram: compute ? compute.zram : null
    readonly property var psiCpu: compute ? compute.psi_cpu : null
    readonly property var psiMem: compute ? compute.psi_mem : null
    readonly property var topCpu: compute && compute.top_cpu ? compute.top_cpu.slice(0, 8) : []
    readonly property var topMem: compute && compute.top_mem ? compute.top_mem.slice(0, 8) : []
    readonly property bool isZramIdle: !zram || !zram.has_zram || (zram.orig_size_bytes || 0) < 1048576

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Row 1: CPU & RAM Gauges
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 138
            Layout.fillHeight: false
            spacing: 10

            // CPU Load Card with full-width bottom sparkline
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "CPU UTILIZATION"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: (compute ? compute.cpu_pct.toFixed(1) : "0.0") + "%"
                            font.family: theme.monoFont
                            font.pixelSize: 28
                            font.bold: true
                            color: theme.textPrimary
                        }

                        Item { Layout.fillWidth: true }

                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: "PSI (avg10 / 60 / 300)"
                                font.family: theme.mainFont
                                font.pixelSize: 9
                                font.bold: true
                                color: theme.textMuted
                                Layout.alignment: Qt.AlignRight
                            }
                            Text {
                                text: psiCpu ? (psiCpu.some_avg10.toFixed(2) + " / " + psiCpu.some_avg60.toFixed(2) + " / " + psiCpu.some_avg300.toFixed(2)) : "0.00 / 0.00 / 0.00"
                                font.family: theme.monoFont
                                font.pixelSize: 10
                                color: theme.textSecondary
                                Layout.alignment: Qt.AlignRight
                            }
                        }
                    }

                    // Full-width Sparkline across card
                    Sparkline {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        values: compute ? compute.sparkline_cpu : []
                        strokeColor: theme.accentWhite
                        maxVal: 100
                        lineWidth: 1.8
                    }
                }
            }

            // RAM Card
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "PHYSICAL MEMORY"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: (compute ? compute.ram_pct.toFixed(1) : "0.0") + "%"
                            font.family: theme.monoFont
                            font.pixelSize: 28
                            font.bold: true
                            color: theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: compute ? (theme.formatBytes(compute.ram_used_bytes) + " / " + theme.formatBytes(compute.ram_total_bytes)) : "0 GB / 0 GB"
                                font.family: theme.monoFont
                                font.pixelSize: 11
                                font.bold: true
                                color: theme.textSecondary
                                Layout.alignment: Qt.AlignRight
                            }
                            Text {
                                text: "used / total"
                                font.family: theme.mainFont
                                font.pixelSize: 9
                                color: theme.textMuted
                                Layout.alignment: Qt.AlignRight
                            }
                        }
                    }

                    // Progress Rail
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: theme.bgInput

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.min(1.0, ((compute ? compute.ram_pct : 0) / 100.0))
                            radius: 3
                            color: theme.accentWhite
                        }
                    }

                    // PSI Memory Stall Row
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "PSI MEMORY STALL"
                            font.family: theme.mainFont
                            font.pixelSize: 9
                            font.bold: true
                            color: theme.textMuted
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: psiMem ? ("SOME: " + psiMem.some_avg10.toFixed(2) + "%   FULL: " + psiMem.full_avg10.toFixed(2) + "%") : "SOME: 0.00%   FULL: 0.00%"
                            font.family: theme.monoFont
                            font.pixelSize: 10
                            font.bold: true
                            color: (psiMem && psiMem.full_avg10 > 0.1) ? theme.accentWhite : theme.textSecondary
                        }
                    }
                }
            }
        }

        // Row 2: ZRAM Compression Card with Capacity Bar
        ZramCard {
            theme: page.theme
            zram: page.zram
            isZramIdle: page.isZramIdle
        }


        // Row 3: Top CPU & Top RAM Processes
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Top CPU Processes Card
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "TOP PROCESSES BY CPU"

                ProcessTable {
                    anchors.fill: parent
                    theme: page.theme
                    model: page.topCpu
                    secondaryWidth: 54
                    primaryWidth: 50
                    emptyText: "Scanning processes..."
                    getSecondaryText: function(item) {
                        if (!item || typeof item.rss_mb !== "number") return "";
                        return item.rss_mb.toFixed(0) + " MB";
                    }
                    getPrimaryText: function(item) {
                        if (!item || typeof item.cpu_pct !== "number") return "";
                        return item.cpu_pct.toFixed(1) + "%";
                    }
                }
            }

            // Top RAM Processes Card
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "TOP PROCESSES BY RAM (RSS)"

                ProcessTable {
                    anchors.fill: parent
                    theme: page.theme
                    model: page.topMem
                    secondaryWidth: 50
                    primaryWidth: 58
                    emptyText: "Scanning processes..."
                    getSecondaryText: function(item) {
                        if (!item || typeof item.cpu_pct !== "number") return "";
                        return item.cpu_pct.toFixed(1) + "%";
                    }
                    getPrimaryText: function(item) {
                        if (!item || typeof item.rss_mb !== "number") return "";
                        return page.theme ? page.theme.formatMb(item.rss_mb) : (item.rss_mb >= 1024 ? (item.rss_mb / 1024.0).toFixed(1) + " GB" : item.rss_mb.toFixed(0) + " MB");
                    }
                }
            }
        }
    }
}
