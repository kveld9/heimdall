import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

MetricCard {
    id: root

    property var theme
    property int failedCount: 0
    property var failedUnits: []
    property string systemState: "running"

    Layout.fillWidth: true
    Layout.preferredHeight: 210
    cardBg: theme ? theme.bgCard : Qt.rgba(1.0, 1.0, 1.0, 0.04)
    cardBorder: theme ? theme.border : Qt.rgba(1.0, 1.0, 1.0, 0.12)
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
                color: root.failedCount === 0 ? (theme ? theme.bgCardHighlight : Qt.rgba(1.0, 1.0, 1.0, 0.08)) : (theme ? theme.bgCardHover : Qt.rgba(1.0, 1.0, 1.0, 0.16))
                border.color: root.failedCount === 0 ? (theme ? theme.border : Qt.rgba(1.0, 1.0, 1.0, 0.12)) : (theme ? theme.accentWhite : "#ffffff")

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        text: root.failedCount === 0 ? "STATUS" : "FAILED"
                        font.family: theme ? theme.mainFont : "sans-serif"
                        font.pixelSize: 9
                        font.bold: true
                        color: root.failedCount === 0 ? (theme ? theme.textMuted : "#9ca3af") : (theme ? theme.accentAlert : "#ffffff")
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: root.failedCount === 0 ? "OK" : root.failedCount.toString()
                        font.family: theme ? theme.monoFont : "Monospace"
                        font.pixelSize: 18
                        font.bold: true
                        color: theme ? theme.accentWhite : "#ffffff"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: root.failedCount === 0 ? "All system daemons normal (0 failed)" : (root.failedCount + " service" + (root.failedCount > 1 ? "s" : "") + " failed:")
                    font.family: theme ? theme.mainFont : "sans-serif"
                    font.pixelSize: 11
                    font.bold: true
                    color: theme ? theme.textPrimary : "#ffffff"
                }

                Text {
                    text: "System State: " + root.systemState
                    font.family: theme ? theme.monoFont : "Monospace"
                    font.pixelSize: 10
                    color: theme ? theme.textSecondary : "#d1d5db"
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06) }

        // Failed units list or Healthy verification
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: failedList
                anchors.fill: parent
                visible: root.failedCount > 0
                model: root.failedUnits
                spacing: 3
                clip: true
                interactive: contentHeight > height

                delegate: RowLayout {
                    width: failedList.width
                    spacing: 6

                    Rectangle { width: 6; height: 6; radius: 3; color: theme ? theme.accentAlert : "#ffffff" }
                    Text {
                        text: modelData
                        font.family: theme ? theme.monoFont : "Monospace"
                        font.pixelSize: 10
                        color: theme ? theme.accentAlert : "#ffffff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                visible: root.failedCount === 0
                spacing: 3

                Text {
                    text: "[v] Core targets, sockets, and mounts active"
                    font.family: theme ? theme.monoFont : "Monospace"
                    font.pixelSize: 10
                    color: theme ? theme.textMuted : "#9ca3af"
                }

                Text {
                    text: "[*] Zero failed units in current systemd transaction"
                    font.family: theme ? theme.monoFont : "Monospace"
                    font.pixelSize: 9
                    color: theme ? theme.textMuted : "#9ca3af"
                }
            }
        }
    }
}
