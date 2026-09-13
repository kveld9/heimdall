import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property var theme
    property string title: "OPTIMAL"
    property string subtitle: ""
    property color indicatorColor: theme ? theme.accentWhite : "#ffffff"
    property bool isAlert: false

    Layout.fillWidth: true
    implicitHeight: 48
    Layout.preferredHeight: implicitHeight
    height: implicitHeight
    radius: 6
    color: root.isAlert ? Qt.rgba(1.0, 1.0, 1.0, 0.16) : (theme ? theme.bgCardHighlight : Qt.rgba(1.0, 1.0, 1.0, 0.06))
    border.color: root.isAlert ? (theme ? theme.accentWhite : "#ffffff") : (theme ? theme.border : Qt.rgba(1.0, 1.0, 1.0, 0.12))

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 10

        // Indicator status dot
        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: root.indicatorColor
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: root.title
                font.family: theme ? theme.mainFont : "sans-serif"
                font.pixelSize: 10
                font.bold: true
                color: theme ? theme.textPrimary : "#ffffff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: root.subtitle.length > 0
                text: root.subtitle
                font.family: theme ? theme.mainFont : "sans-serif"
                font.pixelSize: 9
                color: theme ? theme.textMuted : "#9ca3af"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
