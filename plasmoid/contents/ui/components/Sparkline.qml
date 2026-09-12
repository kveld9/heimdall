import QtQuick

Item {
    id: root

    property var values: []
    property color strokeColor: "#ff79c6"
    property real lineWidth: 2.0
    property real maxVal: 0

    onValuesChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            if (!values || values.length < 2) return;

            var max = root.maxVal;
            if (max <= 0) {
                for (var i = 0; i < values.length; i++) {
                    if (values[i] > max) max = values[i];
                }
            }
            if (max <= 0.1) max = 1.0;

            var step = width / (values.length - 1);
            var padding = 4;
            var usableH = height - (padding * 2);

            ctx.beginPath();
            ctx.strokeStyle = strokeColor;
            ctx.lineWidth = lineWidth;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";

            var points = [];
            for (var j = 0; j < values.length; j++) {
                var x = j * step;
                var ratio = Math.max(0.0, Math.min(1.0, values[j] / max));
                var y = height - padding - (ratio * usableH);
                points.push({x: x, y: y});
            }

            // Draw line
            ctx.moveTo(points[0].x, points[0].y);
            for (var k = 1; k < points.length; k++) {
                ctx.lineTo(points[k].x, points[k].y);
            }
            ctx.stroke();

            // Draw soft fill gradient below line
            ctx.lineTo(width, height);
            ctx.lineTo(0, height);
            ctx.closePath();

            var gradient = ctx.createLinearGradient(0, 0, 0, height);
            var fillBase = strokeColor;
            gradient.addColorStop(0, Qt.rgba(fillBase.r, fillBase.g, fillBase.b, 0.25));
            gradient.addColorStop(1, Qt.rgba(fillBase.r, fillBase.g, fillBase.b, 0.0));
            ctx.fillStyle = gradient;
            ctx.fill();
        }
    }
}
