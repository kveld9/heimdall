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

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // Systemd Health Overview Card
        MetricCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            cardBg: theme.bgCard
            cardBorder: theme.border
            title: "SYSTEMD SERVICE STATE (org.freedesktop.systemd1)"

            RowLayout {
                anchors.fill: parent
                spacing: 20

                // State Badge
                Rectangle {
                    width: 130
                    height: 80
                    radius: 8
                    color: page.failedCount === 0 ? theme.bgCardHighlight : Qt.rgba(1, 0.2, 0.4, 0.15)
                    border.color: page.failedCount === 0 ? theme.accentGreen : theme.accentPink

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            text: page.failedCount === 0 ? "OPTIMAL" : "DEGRADED"
                            font.family: theme.mainFont
                            font.pixelSize: 11
                            font.bold: true
                            color: page.failedCount === 0 ? theme.accentGreen : theme.accentPink
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: page.failedCount + " FAILED"
                            font.family: theme.monoFont
                            font.pixelSize: 16
                            font.bold: true
                            color: theme.textPrimary
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // Details
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: page.failedCount === 0 ? "All system and user background daemons operating without failures." : "Detected failed units requiring inspection:"
                        font.family: theme.mainFont
                        font.pixelSize: 12
                        color: theme.textSecondary
                    }

                    Repeater {
                        model: page.failedUnits
                        Text {
                            text: "✕ " + modelData
                            font.family: theme.monoFont
                            font.pixelSize: 11
                            color: theme.accentPink
                        }
                    }

                    Text {
                        text: "System state: " + (page.health ? page.health.system_state : "running")
                        font.family: theme.monoFont
                        font.pixelSize: 11
                        color: theme.textMuted
                    }
                }
            }
        }

        // Thermal Sensors Card
        MetricCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            cardBg: theme.bgCard
            cardBorder: theme.border
            title: "HARDWARE THERMAL SENSORS (/sys/class/hwmon)"

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Repeater {
                    model: page.sensors

                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        radius: 8
                        color: theme.bgCardHighlight
                        border.color: theme.borderSubtle

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Text {
                                text: modelData.label
                                font.family: theme.monoFont
                                font.pixelSize: 12
                                font.bold: true
                                color: theme.textPrimary
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 70
                                height: 26
                                radius: 5
                                color: modelData.celsius > 75 ? Qt.rgba(1, 0.2, 0.4, 0.2) : theme.bgInput
                                border.color: modelData.celsius > 75 ? theme.accentPink : theme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.celsius.toFixed(1) + " °C"
                                    font.family: theme.monoFont
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: modelData.celsius > 75 ? theme.accentPink : theme.accentGreen
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
