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

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // Top Row: CPU & RAM Gauges
        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            implicitHeight: 180

            // CPU Load Card
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "CPU UTILIZATION"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: (compute ? compute.cpu_pct.toFixed(1) : "0.0") + "%"
                            font.family: theme.monoFont
                            font.pixelSize: 34
                            font.bold: true
                            color: theme.accentGreen
                        }

                        Item { Layout.fillWidth: true }

                        Sparkline {
                            Layout.preferredWidth: 160
                            Layout.fillHeight: true
                            values: compute ? compute.sparkline_cpu : []
                            strokeColor: theme.accentGreen
                            maxVal: 100
                            lineWidth: 2.0
                        }
                    }

                    // Pressure Stall Info (CPU)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: theme.borderSubtle
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "PSI (Pressure avg10/60/300):"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            color: theme.textMuted
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: (psiCpu ? (psiCpu.some_avg10 + " / " + psiCpu.some_avg60 + " / " + psiCpu.some_avg300) : "0.00 / 0.00 / 0.00")
                            font.family: theme.monoFont
                            font.pixelSize: 11
                            color: theme.textSecondary
                        }
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
                            font.pixelSize: 34
                            font.bold: true
                            color: theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: compute ? (theme.formatBytes(compute.ram_used_bytes) + " / " + theme.formatBytes(compute.ram_total_bytes)) : "0 GB / 0 GB"
                                font.family: theme.monoFont
                                font.pixelSize: 12
                                font.bold: true
                                color: theme.textSecondary
                                Layout.alignment: Qt.AlignRight
                            }
                            Text {
                                text: "used / total"
                                font.family: theme.mainFont
                                font.pixelSize: 10
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
                            width: parent.width * ((compute ? compute.ram_pct : 0) / 100.0)
                            radius: 3
                            color: (compute && compute.ram_pct > 85) ? theme.accentPink : theme.accentGreen
                        }
                    }

                    // Memory PSI
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "PSI Mem Full (avg10/60):"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            color: theme.textMuted
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: (psiMem ? (psiMem.full_avg10 + " / " + psiMem.full_avg60) : "0.00 / 0.00")
                            font.family: theme.monoFont
                            font.pixelSize: 11
                            color: (psiMem && psiMem.full_avg10 > 0.5) ? theme.accentPink : theme.textSecondary
                        }
                    }
                }
            }
        }

        // ZRAM Compression Card
        MetricCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            cardBg: theme.bgCard
            cardBorder: theme.border
            title: "ZRAM COMPRESSION TELEMETRY (/sys/block/zram0)"

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    // Compression ratio
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "COMPRESSION RATIO"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textMuted
                        }
                        Text {
                            text: zram ? (zram.ratio.toFixed(2) + ":1") : "1.00:1"
                            font.family: theme.monoFont
                            font.pixelSize: 22
                            font.bold: true
                            color: theme.accentGreen
                        }
                    }

                    // Memory saved
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "SAVED MEMORY"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textMuted
                        }
                        Text {
                            text: zram ? (zram.savings_mb.toFixed(1) + " MB") : "0.0 MB"
                            font.family: theme.monoFont
                            font.pixelSize: 22
                            font.bold: true
                            color: theme.textPrimary
                        }
                    }

                    // Original data size
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "ORIGINAL DATA"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textMuted
                        }
                        Text {
                            text: zram ? theme.formatBytes(zram.orig_size_bytes) : "0 MB"
                            font.family: theme.monoFont
                            font.pixelSize: 22
                            font.bold: true
                            color: theme.textSecondary
                        }
                    }

                    // Compressed data size
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "COMPRESSED IN RAM"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            font.bold: true
                            color: theme.textMuted
                        }
                        Text {
                            text: zram ? theme.formatBytes(zram.compr_size_bytes) : "0 MB"
                            font.family: theme.monoFont
                            font.pixelSize: 22
                            font.bold: true
                            color: theme.accentPink
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: theme.borderSubtle
                }

                Text {
                    text: zram && zram.has_zram ? "● ZRAM kernel driver active · hardware swap compression operating normally" : "○ ZRAM not active"
                    font.family: theme.mainFont
                    font.pixelSize: 11
                    color: theme.textSecondary
                }
            }
        }
    }
}
