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
            Layout.preferredHeight: 125
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
            Layout.preferredHeight: 125
            Layout.fillHeight: false
            cardBg: theme.bgCard
            cardBorder: theme.border
            title: "PHYSICAL STORAGE POOLS & MOUNTPOINTS"

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                Repeater {
                    model: page.partitions

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6
                        color: theme.bgCardHighlight
                        border.color: theme.borderSubtle

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: modelData.mount
                                    font.family: theme.monoFont
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: theme.textPrimary
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: modelData.used_gb + " GB used of " + modelData.total_gb + " GB (" + modelData.free_gb + " GB free)"
                                    font.family: theme.monoFont
                                    font.pixelSize: 11
                                    color: theme.textSecondary
                                }
                                Rectangle {
                                    height: 18
                                    width: 48
                                    radius: 3
                                    color: modelData.used_pct > 90 ? Qt.rgba(1.0, 1.0, 1.0, 0.15) : theme.bgInput
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

                            // Usage Rail
                            Rectangle {
                                Layout.fillWidth: true
                                height: 5
                                radius: 2.5
                                color: theme.bgInput

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width * Math.min(1.0, (modelData.used_pct / 100.0))
                                    radius: 2.5
                                    color: theme.accentWhite
                                }
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
                title: "TOP PROCESSES BY DISK I/O"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6

                    Repeater {
                        model: page.topDiskIo

                        ProcessRow {
                            theme: page.theme
                            rank: index + 1
                            name: modelData.name
                            instances: modelData.instances
                            detailText: "R: " + (modelData.read_mb >= 1024 ? (modelData.read_mb / 1024.0).toFixed(1) + " GB" : modelData.read_mb.toFixed(0) + " MB")
                            badgeText: "W: " + (modelData.write_mb >= 1024 ? (modelData.write_mb / 1024.0).toFixed(1) + " GB" : modelData.write_mb.toFixed(0) + " MB")
                            badgeWidth: 76
                        }
                    }

                    Item {
                        visible: page.topDiskIo.length === 0
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Text {
                            anchors.centerIn: parent
                            text: "Monitoring disk I/O..."
                            font.family: theme.monoFont
                            font.pixelSize: 11
                            color: theme.textMuted
                        }
                    }
                }
            }

            // PSI Status Indicator Card
            MetricCard {
                Layout.preferredWidth: 260
                Layout.fillHeight: true
                cardBg: theme.bgCard
                cardBorder: theme.border
                title: "KERNEL I/O PRESSURE (PSI)"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    // Prominent Status Badge
                    StatusBadge {
                        theme: page.theme
                        title: page.isIoStalled ? "I/O BOTTLENECK DETECTED" : (page.isIoElevated ? "ELEVATED I/O LATENCY" : "I/O PIPELINE OPTIMAL")
                        subtitle: page.isIoStalled ? "Tasks stalled on pagecache flush" : (page.isIoElevated ? "Minor queue contention" : "Zero block device wait states")
                        isAlert: page.isIoStalled
                        indicatorColor: page.isIoStalled ? theme.accentWhite : (page.isIoElevated ? theme.accentSilver : theme.accentWhite)
                    }

                    // Pressure averages breakdown
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "SOME (10s / 60s / 300s):"
                                font.family: theme.mainFont
                                font.pixelSize: 10
                                color: theme.textMuted
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: psiIo ? (psiIo.some_avg10.toFixed(2) + " / " + psiIo.some_avg60.toFixed(2) + " / " + psiIo.some_avg300.toFixed(2)) : "0.00 / 0.00 / 0.00"
                                font.family: theme.monoFont
                                font.pixelSize: 11
                                font.bold: true
                                color: theme.textSecondary
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "FULL (10s / 60s / 300s):"
                                font.family: theme.mainFont
                                font.pixelSize: 10
                                color: theme.textMuted
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: psiIo ? (psiIo.full_avg10.toFixed(2) + " / " + psiIo.full_avg60.toFixed(2) + " / " + psiIo.full_avg300.toFixed(2)) : "0.00 / 0.00 / 0.00"
                                font.family: theme.monoFont
                                font.pixelSize: 11
                                font.bold: true
                                color: page.isIoStalled ? theme.accentWhite : theme.textSecondary
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
