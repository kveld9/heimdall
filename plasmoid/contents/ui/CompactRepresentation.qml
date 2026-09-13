import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid

Item {
    id: compact

    readonly property var telemetry: root.telemetry
    readonly property var theme: root.theme

    implicitWidth: 84
    implicitHeight: 28

    RowLayout {
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: theme ? theme.accentWhite : "#ffffff"
        }

        Text {
            text: (telemetry && telemetry.net) ? ("v " + theme.formatSpeed(telemetry.net.down_rate_kb)) : "Heimdall"
            font.family: theme ? theme.monoFont : "monospace"
            font.pixelSize: 11
            font.bold: true
            color: theme ? theme.textPrimary : "#ffffff"
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: "Toggle Heimdall dashboard"

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: "Toggle Heimdall dashboard"
        onClicked: root.expanded = !root.expanded
    }
}
