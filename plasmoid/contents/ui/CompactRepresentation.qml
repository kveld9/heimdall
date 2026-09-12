import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid

Item {
    id: compact

    readonly property var telemetry: root.telemetry
    readonly property var theme: root.theme

    implicitWidth: 70
    implicitHeight: 28

    RowLayout {
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: theme.accentGreen
        }

        Text {
            text: (telemetry && telemetry.net) ? theme.formatSpeed(telemetry.net.down_rate_kb) : "WatchCat"
            font.family: theme.monoFont
            font.pixelSize: 11
            font.bold: true
            color: theme.textPrimary
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded
    }
}
