import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    Theme {
        id: appTheme
    }

    property var telemetry: null
    property var theme: appTheme
    property bool daemonConnected: false
    property bool isCollapsed: false

    implicitWidth: isCollapsed ? theme.capsuleWidth : theme.expandedWidth
    implicitHeight: isCollapsed ? theme.capsuleHeight : theme.expandedHeight

    Behavior on implicitWidth {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }
    Behavior on implicitHeight {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }


    property string apiEndpoint: "http://127.0.0.1:9871/api/telemetry"
    property int pollTimeoutMs: 900
    property int pollIntervalMs: 1000

    // Zero-jank Asynchronous HTTP Fetch
    function fetchTelemetry() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", root.apiEndpoint, true);
        xhr.timeout = root.pollTimeoutMs;

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        root.telemetry = JSON.parse(xhr.responseText);
                        root.daemonConnected = true;
                    } catch(e) {
                        root.daemonConnected = false;
                    }
                } else {
                    root.daemonConnected = false;
                }
            }
        };

        xhr.ontimeout = function() {
            root.daemonConnected = false;
        };

        xhr.onerror = function() {
            root.daemonConnected = false;
        };

        try {
            xhr.send();
        } catch(e) {
            root.daemonConnected = false;
        }
    }

    // Refresh timer
    Timer {
        id: pollTimer
        interval: root.pollIntervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchTelemetry()
    }

    preferredRepresentation: fullRepresentation
    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}
}
