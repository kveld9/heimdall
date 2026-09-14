import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"

Item {
    id: page

    property var theme
    property var telemetry: null

    readonly property var storage: telemetry ? telemetry.storage : null
    readonly property var partitions: storage ? storage.partitions : []
    readonly property var psiIo: storage ? storage.psi_io : null
    readonly property var topDiskIo: storage && storage.top_disk_io ? storage.top_disk_io : []

    // Helper for PSI status
    readonly property bool isIoStalled: psiIo && (psiIo.full_avg10 > 0.2 || psiIo.some_avg10 > 1.0)
    readonly property bool isIoElevated: psiIo && !isIoStalled && (psiIo.full_avg10 > 0.0 || psiIo.some_avg10 > 0.1)
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Row 1: Read & Write Throughput Cards with Sparklines
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            Layout.fillHeight: false
            spacing: 10

            // Read Card
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "DISK READ THROUGHPUT"

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: (storage ? storage.read_mb_s.toFixed(2) : "0.00") + " MB/s"
                            font.family: theme.monoFont
                            font.pixelSize: 24
                            font.bold: true
                            color: theme.accentWhite
                        }
                        Text {
                            text: "Sequential & random block reads"
                            font.family: theme.mainFont
                            font.pixelSize: 9
                            color: theme.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Sparkline {
                        Layout.preferredWidth: 140
                        Layout.fillHeight: true
                        values: storage ? storage.sparkline_read : []
                        strokeColor: theme.accentWhite
                        lineWidth: 1.8
                    }
                }
            }

            // Write Card
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "DISK WRITE THROUGHPUT"

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: (storage ? storage.write_mb_s.toFixed(2) : "0.00") + " MB/s"
                            font.family: theme.monoFont
                            font.pixelSize: 24
                            font.bold: true
                            color: theme.accentWhite
                        }
                        Text {
                            text: "Sync & journal block writes"
                            font.family: theme.mainFont
                            font.pixelSize: 9
                            color: theme.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Sparkline {
                        Layout.preferredWidth: 140
                        Layout.fillHeight: true
                        values: storage ? storage.sparkline_write : []
                        strokeColor: theme.accentSilver
                        lineWidth: 1.8
                    }
                }
            }
        }

        // Row 2: Mounted Filesystems (Deduplicated physical devices)
        MetricCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            Layout.fillHeight: false
            cardBg: theme.bgCard
            cardBorder: theme.border
            title: "PHYSICAL STORAGE POOLS & MOUNTPOINTS"

            ListView {
                id: poolsList
                anchors.fill: parent
                clip: true
                spacing: 6
                model: page.partitions
                interactive: contentHeight > height

                delegate: Rectangle {
                    width: poolsList.width
                    height: 44
                    radius: 6
                    color: theme.bgCardHighlight
                    border.color: theme.borderSubtle

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: modelData.mount
                                font.family: theme.monoFont
                                font.pixelSize: 11
                                font.bold: true
                                color: theme.textPrimary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: modelData.used_gb + " GB used of " + modelData.total_gb + " GB (" + modelData.free_gb + " GB free)"
                                font.family: theme.monoFont
                                font.pixelSize: 10
                                color: theme.textSecondary
                            }
                            Rectangle {
                                height: 16
                                width: 44
                                radius: 3
                                color: modelData.used_pct > 90 ? (theme ? theme.bgPillStrong : Qt.rgba(1.0, 1.0, 1.0, 0.15)) : theme.bgInput
                                border.color: theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.used_pct + "%"
                                    font.family: theme.monoFont
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: theme.accentWhite
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: 2
                            color: theme.bgInput

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * Math.min(1.0, (modelData.used_pct / 100.0))
                                radius: 2
                                color: theme.accentWhite
                            }
                        }
                    }
                }
            }
        }
        // Row 3: Top Disk I/O Consumers & PSI Status
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Top Disk I/O Processes
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "TOP PROCESSES BY LIFETIME DISK I/O"

                ProcessTable {
                    anchors.fill: parent
                    theme: page.theme
                    model: page.topDiskIo
                    secondaryWidth: 72
                    primaryWidth: 72
                    emptyText: "Monitoring disk I/O..."
                    getSecondaryText: function(item) {
                        if (!item || typeof item.read_mb !== "number") return "";
                        return "R: " + (page.theme ? page.theme.formatMb(item.read_mb) : (item.read_mb >= 1024 ? (item.read_mb / 1024.0).toFixed(1) + " GB" : item.read_mb.toFixed(0) + " MB"));
                    }
                    getPrimaryText: function(item) {
                        if (!item || typeof item.write_mb !== "number") return "";
                        return page.theme ? page.theme.formatMb(item.write_mb) : (item.write_mb >= 1024 ? (item.write_mb / 1024.0).toFixed(1) + " GB" : item.write_mb.toFixed(0) + " MB");
                    }
                }
            }

            // PSI Status Indicator Card
            MetricCard {
                Layout.preferredWidth: 260
                Layout.minimumWidth: 220
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "KERNEL I/O PRESSURE (PSI)"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    // Prominent Status Badge
                    StatusBadge {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        theme: page.theme
                        title: page.isIoStalled ? "I/O BOTTLENECK DETECTED" : (page.isIoElevated ? "ELEVATED I/O LATENCY" : "I/O PIPELINE OPTIMAL")
                        subtitle: page.isIoStalled ? "Tasks stalled on pagecache flush" : (page.isIoElevated ? "Minor queue contention" : "Zero block device wait states")
                        isAlert: page.isIoStalled
                        indicatorColor: page.isIoStalled ? theme.accentWhite : (page.isIoElevated ? theme.accentSilver : theme.accentWhite)
                    }

                    // Pressure averages breakdown
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "SOME (10s · 60s · 300s)"
                            font.family: theme.mainFont
                            font.pixelSize: 9
                            font.bold: true
                            color: theme.textMuted
                        }
                        Text {
                            text: psiIo ? (psiIo.some_avg10.toFixed(2) + " · " + psiIo.some_avg60.toFixed(2) + " · " + psiIo.some_avg300.toFixed(2)) : "0.00 · 0.00 · 0.00"
                            font.family: theme.monoFont
                            font.pixelSize: 11
                            font.bold: true
                            color: theme.textSecondary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "FULL (10s · 60s · 300s)"
                            font.family: theme.mainFont
                            font.pixelSize: 9
                            font.bold: true
                            color: theme.textMuted
                        }
                        Text {
                            text: psiIo ? (psiIo.full_avg10.toFixed(2) + " · " + psiIo.full_avg60.toFixed(2) + " · " + psiIo.full_avg300.toFixed(2)) : "0.00 · 0.00 · 0.00"
                            font.family: theme.monoFont
                            font.pixelSize: 11
                            font.bold: true
                            color: page.isIoStalled ? theme.accentWhite : theme.textSecondary
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
