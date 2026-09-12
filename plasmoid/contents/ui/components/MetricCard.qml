import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card

    property alias title: titleLabel.text
    property alias headerRight: rightHeaderItem.data
    property color cardBg: Qt.rgba(1.0, 1.0, 1.0, 0.04)
    property color cardBorder: Qt.rgba(1.0, 1.0, 1.0, 0.09)
    property real radiusVal: 12

    color: cardBg
    border.color: cardBorder
    border.width: 1
    radius: radiusVal
    clip: true

    default property alias content: innerContainer.data

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header (optional)
        RowLayout {
            Layout.fillWidth: true
            visible: titleLabel.text.length > 0 || rightHeaderItem.children.length > 0

            Text {
                id: titleLabel
                text: ""
                font.family: "sans-serif"
                font.pixelSize: 10
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.2
                color: "#9ca3af"
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Item {
                id: rightHeaderItem
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: childrenRect.width
                implicitHeight: childrenRect.height
            }
        }

        // Inner body
        Item {
            id: innerContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
