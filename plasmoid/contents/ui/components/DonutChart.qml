import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var theme
    property int downPct: 55
    property int upPct: 45
    property string downBytesStr: "45 MB"
    property string upBytesStr: "38 MB"
    property color colorDown: theme.accentWhite
    property color colorUp: theme.accentDarkGrey

    implicitWidth: 200
    implicitHeight: 200

    onDownPctChanged: canvas.requestPaint()
    onUpPctChanged: canvas.requestPaint()

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 120

            Canvas {
                id: canvas
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height) - 10
                height: width
                antialiasing: true

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    var centerX = width / 2;
                    var centerY = height / 2;
                    var radius = (width / 2) - 14;
                    var ringWidth = 14;

                    var total = Math.max(1, root.downPct + root.upPct);
                    var downAngle = (root.downPct / total) * 2 * Math.PI;

                    // Draw Down arc (pink)
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + downAngle, false);
                    ctx.strokeStyle = root.colorDown;
                    ctx.lineWidth = ringWidth;
                    ctx.lineCap = "round";
                    ctx.stroke();

                    // Draw Up arc (green)
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, -Math.PI / 2 + downAngle + 0.1, -Math.PI / 2 + (2 * Math.PI) - 0.1, false);
                    ctx.strokeStyle = root.colorUp;
                    ctx.lineWidth = ringWidth;
                    ctx.lineCap = "round";
                    ctx.stroke();
                }
            }

            // Center Text inside the donut
            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.downPct + "%"
                    font.family: theme.monoFont
                    font.pixelSize: 24
                    font.bold: true
                    color: theme.textPrimary
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "DOWN"
                    font.family: theme.mainFont
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.0
                    color: theme.textSecondary
                }
            }
        }

        // Legend Row
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            RowLayout {
                spacing: 6
                Rectangle {
                    width: 8
                    height: 8
                    radius: 2
                    color: root.colorDown
                }
                Text {
                    text: "down " + root.downBytesStr
                    font.family: theme.mainFont
                    font.pixelSize: 11
                    color: theme.textSecondary
                }
            }

            RowLayout {
                spacing: 6
                Rectangle {
                    width: 8
                    height: 8
                    radius: 2
                    color: root.colorUp
                }
                Text {
                    text: "up " + root.upBytesStr
                    font.family: theme.mainFont
                    font.pixelSize: 11
                    color: theme.textSecondary
                }
            }
        }
    }
}
