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

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // Top Row: Disk Read & Write Sparklines
        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            implicitHeight: 120

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
                            color: theme.accentGreen
                        }
                        Text {
                            text: "Sustained sequential & random reads"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            color: theme.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Sparkline {
                        Layout.preferredWidth: 140
                        Layout.fillHeight: true
                        values: storage ? storage.sparkline_read : []
                        strokeColor: theme.accentGreen
                        lineWidth: 2.0
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
                            color: theme.accentPink
                        }
                        Text {
                            text: "Sync & async block writes"
                            font.family: theme.mainFont
                            font.pixelSize: 10
                            color: theme.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Sparkline {
                        Layout.preferredWidth: 140
                        Layout.fillHeight: true
                        values: storage ? storage.sparkline_write : []
                        strokeColor: theme.accentPink
                        lineWidth: 2.0
                    }
                }
            }
        }

        // Middle Card: Mounted Filesystems
        MetricCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            cardBg: theme.bgCard
            cardBorder: theme.border
            title: "MOUNTED FILESYSTEMS & CAPACITIES"

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                Repeater {
                    model: page.partitions

                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: 8
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
                                    font.pixelSize: 13
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
                                Text {
                                    text: modelData.used_pct + "%"
                                    font.family: theme.monoFont
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: modelData.used_pct > 90 ? theme.accentPink : theme.accentGreen
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
                                    width: parent.width * (modelData.used_pct / 100.0)
                                    radius: 2.5
                                    color: modelData.used_pct > 90 ? theme.accentPink : theme.accentGreen
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // Bottom Card: I/O PSI
        MetricCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            cardBg: theme.bgCard
            cardBorder: theme.border
            title: "I/O PRESSURE STALL INFORMATION (/proc/pressure/io)"

            RowLayout {
                anchors.fill: parent
                spacing: 20

                Text {
                    text: "I/O SOME: " + (psiIo ? (psiIo.some_avg10 + " / " + psiIo.some_avg60 + " / " + psiIo.some_avg300) : "0.00 / 0.00 / 0.00")
                    font.family: theme.monoFont
                    font.pixelSize: 12
                    color: theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "I/O FULL: " + (psiIo ? (psiIo.full_avg10 + " / " + psiIo.full_avg60 + " / " + psiIo.full_avg300) : "0.00 / 0.00 / 0.00")
                    font.family: theme.monoFont
                    font.pixelSize: 12
                    color: (psiIo && psiIo.full_avg10 > 0.5) ? theme.accentPink : theme.textSecondary
                }
            }
        }
    }
}
