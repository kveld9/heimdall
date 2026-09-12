import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "pages"

Rectangle {
    id: full

    readonly property var theme: root.theme
    readonly property var telemetry: root.telemetry

    color: theme.bgPrimary
    border.color: theme.border
    border.width: 1
    radius: 12
    clip: true

    implicitWidth: 720
    implicitHeight: 560
    Layout.minimumWidth: 620
    Layout.minimumHeight: 500
    Layout.preferredWidth: 720
    Layout.preferredHeight: 560

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header with Logo, live rates, tabs, and theme switcher
        Header {
            id: header
            Layout.fillWidth: true
            theme: root.theme
            telemetry: root.telemetry
            currentPage: stack.currentIndex
            onPageSelected: function(idx) {
                stack.currentIndex = idx;
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: theme.borderSubtle
        }

        // 4 Multi-page Stack
        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            NetworkPage {
                theme: root.theme
                telemetry: root.telemetry
            }

            ComputePage {
                theme: root.theme
                telemetry: root.telemetry
            }

            StoragePage {
                theme: root.theme
                telemetry: root.telemetry
            }

            SystemdPage {
                theme: root.theme
                telemetry: root.telemetry
            }
        }
    }
}
