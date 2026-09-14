import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    property var theme
    property var model: []
    property var sparkline: []
    property var fans: []
    property var voltages: []
    readonly property real tempWarnThreshold: 65.0
    readonly property real tempCritThreshold: 80.0

    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgCardHighlight : "#16181c"
        radius: 8
        border.color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6

            // Section 1: Temperature sensors with relative gauge rails
            ListView {
                id: sensorsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                interactive: contentHeight > height
                model: Array.isArray(root.model) ? root.model : []
                spacing: 4

                delegate: Rectangle {
                    width: sensorsList.width
                    height: 46
                    radius: 6
                    color: theme ? theme.bgCard : Qt.rgba(1.0, 1.0, 1.0, 0.04)
                    border.color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 3

                        // Row 1: Label, Status, and Temp Pill
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: (index + 1) + "."
                                font.family: theme ? theme.monoFont : "Monospace"
                                font.pixelSize: 10
                                color: theme ? theme.textDim : "#666666"
                                Layout.preferredWidth: 18
                            }

                            Text {
                                text: (modelData && modelData.label) ? modelData.label : "Sensor"
                                font.family: theme ? theme.monoFont : "Monospace"
                                font.pixelSize: 11
                                font.bold: true
                                color: theme ? theme.textPrimary : "#ffffff"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: (modelData && typeof modelData.celsius === "number") ? (modelData.celsius >= root.tempCritThreshold ? "HOT" : (modelData.celsius >= root.tempWarnThreshold ? "WARM" : "OPTIMAL")) : "N/A"
                                font.family: theme ? theme.mainFont : "sans-serif"
                                font.pixelSize: 9
                                font.bold: true
                                color: (modelData && typeof modelData.celsius === "number") ? (modelData.celsius >= root.tempCritThreshold ? (theme ? theme.accentAlert : "#ffffff") : (modelData.celsius >= root.tempWarnThreshold ? (theme ? theme.accentSilver : "#d1d5db") : (theme ? theme.textMuted : "#9ca3af"))) : (theme ? theme.textDim : "#666666")
                                horizontalAlignment: Text.AlignRight
                            }

                            Rectangle {
                                Layout.preferredWidth: 56
                                Layout.preferredHeight: 18
                                radius: 3
                                color: (modelData && typeof modelData.celsius === "number" && modelData.celsius >= root.tempCritThreshold) ? (theme ? theme.bgCardHover : Qt.rgba(1.0, 1.0, 1.0, 0.16)) : (theme ? theme.bgPill : Qt.rgba(1.0, 1.0, 1.0, 0.08))
                                border.color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)
                                Layout.alignment: Qt.AlignRight

                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData && typeof modelData.celsius === "number") ? modelData.celsius.toFixed(1) + " °C" : "--.- °C"
                                    font.family: theme ? theme.monoFont : "Monospace"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: theme ? theme.accentWhite : "#ffffff"
                                }
                            }
                        }

                        // Row 2: Relative Temperature Gauge Rail
                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: 2
                            color: theme ? theme.bgInput : Qt.rgba(0.0, 0.0, 0.0, 0.45)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * Math.min(1.0, Math.max(0.04, ((modelData && typeof modelData.celsius === "number") ? modelData.celsius : 0) / ((modelData && modelData.crit > 0) ? modelData.crit : 100.0)))
                                radius: 2
                                color: (modelData && typeof modelData.celsius === "number" && modelData.celsius >= root.tempCritThreshold) ? (theme ? theme.accentWhite : "#ffffff") : (modelData && typeof modelData.celsius === "number" && modelData.celsius >= root.tempWarnThreshold ? (theme ? theme.accentSilver : "#d1d5db") : (theme ? theme.accentWhite : "#ffffff"))
                            }
                        }
                    }
                }
            }

            // Section 2: Hardware Telemetry Trend & Secondary Metrics (Bottom Footer)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                radius: 6
                color: theme ? theme.bgCard : Qt.rgba(1.0, 1.0, 1.0, 0.04)
                border.color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 3

                    // Telemetry Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "THERMAL TREND"
                            font.family: theme ? theme.mainFont : "sans-serif"
                            font.pixelSize: 9
                            font.bold: true
                            color: theme ? theme.textMuted : "#9ca3af"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        // Fan speed badge if available
                        RowLayout {
                            spacing: 4
                            visible: Array.isArray(root.fans) && root.fans.length > 0
                            Repeater {
                                model: root.fans ? root.fans.slice(0, 1) : []
                                Rectangle {
                                    height: 16
                                    width: 68
                                    radius: 3
                                    color: theme ? theme.bgPill : Qt.rgba(1.0, 1.0, 1.0, 0.08)
                                    border.color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.rpm + " RPM"
                                        font.family: theme ? theme.monoFont : "Monospace"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: theme ? theme.accentWhite : "#ffffff"
                                    }
                                }
                            }
                        }

                        // Voltage badge if available
                        RowLayout {
                            spacing: 4
                            visible: Array.isArray(root.voltages) && root.voltages.length > 0
                            Repeater {
                                model: root.voltages ? root.voltages.slice(0, 1) : []
                                Rectangle {
                                    height: 16
                                    width: 72
                                    radius: 3
                                    color: theme ? theme.bgPill : Qt.rgba(1.0, 1.0, 1.0, 0.08)
                                    border.color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)
                                    Text {
                                        anchors.centerIn: parent
                                        text: (modelData.label ? modelData.label.split(" ").slice(-1)[0] : "V") + " " + modelData.volts + "V"
                                        font.family: theme ? theme.monoFont : "Monospace"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: theme ? theme.accentSilver : "#d1d5db"
                                    }
                                }
                            }
                        }
                    }

                    // Temperature Sparkline across full width
                    Sparkline {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        values: root.sparkline
                        strokeColor: theme ? theme.accentWhite : "#ffffff"
                        maxVal: 100
                        lineWidth: 1.6
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !root.model || root.model.length === 0
            text: "Scanning thermal sensors..."
            font.family: theme ? theme.monoFont : "Monospace"
            font.pixelSize: 11
            color: theme ? theme.textMuted : "#9ca3af"
        }
    }
}
