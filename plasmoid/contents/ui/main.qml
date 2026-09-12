import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    property var telemetry: null
    property var theme: appTheme
    property bool daemonConnected: false

    Theme {
        id: appTheme
    }

    // Zero-jank Asynchronous HTTP Fetch
    function fetchTelemetry() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "http://127.0.0.1:9871/api/telemetry", true);
        xhr.timeout = 900;

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        root.telemetry = JSON.parse(xhr.responseText);
                        root.daemonConnected = true;
                    } catch(e) {
                        // ignore parse error
                    }
                } else {
                    root.daemonConnected = false;
                }
            }
        };

        xhr.ontimeout = function() {
            root.daemonConnected = false;
        };

        try {
            xhr.send();
        } catch(e) {
            root.daemonConnected = false;
        }
    }

    // Refresh timer (1 Hz)
    Timer {
        id: pollTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchTelemetry()
    }

    preferredRepresentation: fullRepresentation
    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}
}
