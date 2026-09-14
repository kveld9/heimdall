import QtQuick
import QtQuick.Layouts

MetricCard {
    id: root

    property var zram: null
    property bool isZramIdle: true

    Layout.fillWidth: true
    Layout.preferredHeight: 114
    Layout.fillHeight: false
    title: "ZRAM COMPRESSION ENGINE (/sys/block/zram0)"

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                spacing: 1
                Text {
                    text: "RATIO"
                    font.family: theme ? theme.mainFont : "sans-serif"
                    font.pixelSize: 9
                    font.bold: true
                    color: theme ? theme.textMuted : "#9ca3af"
                }
                Text {
                    text: root.isZramIdle ? "1.00:1 (Idle)" : (root.zram && root.zram.ratio > 0 ? (root.zram.ratio.toFixed(2) + ":1") : "1.00:1")
                    font.family: theme ? theme.monoFont : "Monospace"
                    font.pixelSize: 15
                    font.bold: true
                    color: theme ? theme.accentWhite : "#ffffff"
                }
            }

            Rectangle { width: 1; height: 26; color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06) }

            ColumnLayout {
                spacing: 1
                Text {
                    text: "SAVED RAM"
                    font.family: theme ? theme.mainFont : "sans-serif"
                    font.pixelSize: 9
                    font.bold: true
                    color: theme ? theme.textMuted : "#9ca3af"
                }
                Text {
                    text: root.zram ? (root.zram.savings_mb.toFixed(1) + " MB") : "0.0 MB"
                    font.family: theme ? theme.monoFont : "Monospace"
                    font.pixelSize: 15
                    font.bold: true
                    color: theme ? theme.textPrimary : "#ffffff"
                }
            }

            Rectangle { width: 1; height: 26; color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06) }

            ColumnLayout {
                spacing: 1
                Text {
                    text: "ORIGINAL / IN RAM"
                    font.family: theme ? theme.mainFont : "sans-serif"
                    font.pixelSize: 9
                    font.bold: true
                    color: theme ? theme.textMuted : "#9ca3af"
                }
                Text {
                    text: root.zram ? (theme.formatBytes(root.zram.orig_size_bytes) + " -> " + theme.formatBytes(root.zram.compr_size_bytes)) : "0 B -> 0 B"
                    font.family: theme ? theme.monoFont : "Monospace"
                    font.pixelSize: 12
                    font.bold: true
                    color: theme ? theme.textSecondary : "#d1d5db"
                }
            }

            Item { Layout.fillWidth: true }

            ColumnLayout {
                spacing: 1
                Text {
                    text: "POOL ALLOCATION"
                    font.family: theme ? theme.mainFont : "sans-serif"
                    font.pixelSize: 9
                    font.bold: true
                    color: theme ? theme.textMuted : "#9ca3af"
                    Layout.alignment: Qt.AlignRight
                }
                Text {
                    text: root.zram ? (theme.formatBytes(root.zram.compr_size_bytes) + " of " + theme.formatBytes(root.zram.capacity_bytes)) : "0 B / 0 B"
                    font.family: theme ? theme.monoFont : "Monospace"
                    font.pixelSize: 12
                    font.bold: true
                    color: theme ? theme.textSecondary : "#d1d5db"
                    Layout.alignment: Qt.AlignRight
                }
            }
        }

        // ZRAM Capacity Fill Bar
        Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: theme ? theme.bgInput : Qt.rgba(0.0, 0.0, 0.0, 0.45)

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root.isZramIdle ? 8 : parent.width * Math.min(1.0, ((root.zram && root.zram.usage_pct) ? (root.zram.usage_pct / 100.0) : 0.005))
                radius: 3
                color: root.isZramIdle ? (theme ? theme.accentGrey : "#9ca3af") : (theme ? theme.accentWhite : "#ffffff")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.isZramIdle ? ("[*] ZRAM Idle (" + (root.zram ? theme.formatBytes(root.zram.orig_size_bytes) : "0 B") + " in use · " + (root.zram ? theme.formatBytes(root.zram.capacity_bytes) : "0 B") + " headroom)") : ("[*] Hardware compression active: " + root.zram.usage_pct.toFixed(2) + "% of total device capacity utilized")
                font.family: theme ? theme.monoFont : "Monospace"
                font.pixelSize: 10
                color: theme ? theme.textMuted : "#9ca3af"
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "Mem used: " + (root.zram ? theme.formatBytes(root.zram.mem_used_bytes) : "0 B")
                font.family: theme ? theme.monoFont : "Monospace"
                font.pixelSize: 10
                color: theme ? theme.textMuted : "#9ca3af"
            }
        }
    }
}
