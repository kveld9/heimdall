import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."

Item {
    id: root

    Theme {
        id: fallbackTheme
    }

    property var theme: fallbackTheme
    property var model: []

    Rectangle {
        anchors.fill: parent
        color: theme ? theme.bgCardHighlight : Qt.rgba(1.0, 1.0, 1.0, 0.08)
        radius: 8
        border.color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)
        border.width: 1
        clip: true

        ListView {
            id: timersList
            anchors.fill: parent
            anchors.margins: 4
            interactive: contentHeight > height
            model: Array.isArray(root.model) ? root.model.slice(0, 8) : []
            spacing: 0
            clip: true

            delegate: Item {
                width: timersList.width
                height: 34

                // Subtle bottom separator line
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: theme ? theme.bgTableSeparator : Qt.rgba(1.0, 1.0, 1.0, 0.04)
                    visible: index < Math.min(root.model ? root.model.length - 1 : 0, 7)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    // Column 1: Index (fixed width 24 px, dimmed text)
                    Text {
                        text: (index + 1) + "."
                        font.family: theme ? theme.monoFont : "Monospace"
                        font.pixelSize: 11
                        color: theme ? theme.textDim : "#666666"
                        Layout.preferredWidth: 24
                    }

                    // Column 2: Full timer unit name (fillWidth, elide right)
                    Text {
                        text: (modelData && modelData.unit) ? (modelData.unit.endsWith(".timer") ? modelData.unit : (modelData.unit + ".timer")) : ""
                        font.family: theme ? theme.monoFont : "Monospace"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: theme ? theme.textSecondary : "#e0e0e0"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.minimumWidth: 80
                    }

                    // Countdown pill (fixed width 68 px, bold, right aligned)
                    Rectangle {
                        Layout.preferredWidth: 68
                        Layout.preferredHeight: 20
                        radius: 4
                        color: theme ? theme.bgPill : Qt.rgba(1.0, 1.0, 1.0, 0.08)
                        border.color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)
                        Layout.alignment: Qt.AlignRight

                        Text {
                            anchors.centerIn: parent
                            text: (modelData && modelData.left_str) ? modelData.left_str : ""
                            font.family: theme ? theme.monoFont : "Monospace"
                            font.pixelSize: 10
                            font.bold: true
                            color: theme ? theme.accentWhite : "#ffffff"
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !root.model || root.model.length === 0
            text: "Scanning scheduled timers..."
            font.family: theme ? theme.monoFont : "Monospace"
            font.pixelSize: 11
            color: theme ? theme.textMuted : "#9ca3af"
        }
    }
}
