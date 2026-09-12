import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property var theme
    property int rank: 1
    property string name: ""
    property int instances: 1
    property string detailText: ""
    property string badgeText: ""
    property real detailWidth: 70
    property real badgeWidth: 64
    property real rightMarginVal: 16

    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 6
    color: theme ? theme.bgCardHighlight : Qt.rgba(1.0, 1.0, 1.0, 0.06)
    border.color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.08)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: root.rightMarginVal
        spacing: 8

        // Rank number
        Text {
            text: root.rank + "."
            font.family: theme ? theme.monoFont : "monospace"
            font.pixelSize: 11
            font.bold: true
            color: theme ? theme.textMuted : "#9ca3af"
            Layout.preferredWidth: 18
        }

        // Process comm name + optional multi-instance badge
        RowLayout {
            spacing: 6
            Layout.fillWidth: true

            Text {
                text: root.name
                font.family: theme ? theme.monoFont : "monospace"
                font.pixelSize: 11
                font.bold: true
                color: theme ? theme.textPrimary : "#ffffff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                visible: root.instances > 1
                height: 14
                width: instText.implicitWidth + 8
                radius: 3
                color: theme ? theme.bgInput : Qt.rgba(0.0, 0.0, 0.0, 0.45)

                Text {
                    id: instText
                    anchors.centerIn: parent
                    text: "x" + root.instances
                    font.family: theme ? theme.monoFont : "monospace"
                    font.pixelSize: 9
                    color: theme ? theme.textMuted : "#9ca3af"
                }
            }
        }

        // Secondary detail text (e.g. RAM RSS or Read MB) - STRICT TABULAR COLUMN
        Text {
            visible: root.detailText.length > 0
            text: root.detailText
            font.family: theme ? theme.monoFont : "monospace"
            font.pixelSize: 10
            color: theme ? theme.textSecondary : "#d1d5db"
            Layout.preferredWidth: root.detailWidth
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignRight
        }

        // Primary metric badge (e.g. CPU % or Write MB) - STRICT TABULAR COLUMN
        Rectangle {
            height: 20
            Layout.preferredWidth: root.badgeWidth
            radius: 4
            color: Qt.rgba(1.0, 1.0, 1.0, 0.08)
            border.color: theme ? theme.border : Qt.rgba(1.0, 1.0, 1.0, 0.12)
            Layout.alignment: Qt.AlignRight

            Text {
                id: badgeVal
                anchors.centerIn: parent
                text: root.badgeText
                font.family: theme ? theme.monoFont : "monospace"
                font.pixelSize: 10
                font.bold: true
                color: theme ? theme.accentWhite : "#ffffff"
            }
        }
    }
}
