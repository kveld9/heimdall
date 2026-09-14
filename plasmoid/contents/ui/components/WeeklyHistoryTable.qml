import QtQuick
import QtQuick.Layouts

MetricCard {
    id: root

    property var theme
    property var weeklyList: []
    property real maxWeekBytes: 1
    property real colDayWidth: 42
    property real colDateWidth: 40
    property real colDownWidth: 54
    property real colUpWidth: 54
    property real colTotalWidth: 80

    Layout.fillWidth: true
    Layout.fillHeight: true
    cardBg: theme ? theme.bgCard : Qt.rgba(1.0, 1.0, 1.0, 0.04)
    cardBorder: theme ? theme.border : Qt.rgba(1.0, 1.0, 1.0, 0.09)
    title: "THIS WEEK - BY DAY"

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        // Table Header with high contrast
        Item {
            Layout.fillWidth: true
            implicitHeight: 18

            Text {
                id: hDay
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                width: root.colDayWidth
                text: "DAY"
                font.family: theme ? theme.mainFont : "sans-serif"
                font.pixelSize: 10
                font.bold: true
                color: theme ? theme.textSecondary : "#d1d5db"
            }

            Text {
                id: hDate
                x: hDay.x + root.colDayWidth + 6
                anchors.verticalCenter: parent.verticalCenter
                width: root.colDateWidth
                text: "DATE"
                font.family: theme ? theme.mainFont : "sans-serif"
                font.pixelSize: 10
                font.bold: true
                color: theme ? theme.textSecondary : "#d1d5db"
            }

            Text {
                id: hTotal
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: root.colTotalWidth
                text: "TOTAL"
                font.family: theme ? theme.mainFont : "sans-serif"
                font.pixelSize: 10
                font.bold: true
                color: theme ? theme.textSecondary : "#d1d5db"
                horizontalAlignment: Text.AlignRight
            }

            Text {
                id: hUp
                anchors.right: hTotal.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: root.colUpWidth
                text: "^ UP"
                font.family: theme ? theme.mainFont : "sans-serif"
                font.pixelSize: 10
                font.bold: true
                color: theme ? theme.textSecondary : "#d1d5db"
                horizontalAlignment: Text.AlignRight
            }

            Text {
                id: hDown
                anchors.right: hUp.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: root.colDownWidth
                text: "v DOWN"
                font.family: theme ? theme.mainFont : "sans-serif"
                font.pixelSize: 10
                font.bold: true
                color: theme ? theme.textSecondary : "#d1d5db"
                horizontalAlignment: Text.AlignRight
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)
        }

        // Table Rows
        ListView {
            id: weekListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.weeklyList
            spacing: 2

            delegate: Rectangle {
                width: weekListView.width
                height: 20
                radius: 4
                color: (modelData && modelData.is_today) ? (theme ? theme.bgCardHighlight : Qt.rgba(1.0, 1.0, 1.0, 0.08)) : "transparent"

                Text {
                    id: dDay
                    x: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.colDayWidth
                    text: (modelData && modelData.day) ? modelData.day : ""
                    font.family: theme ? theme.mainFont : "sans-serif"
                    font.pixelSize: 11
                    font.bold: !!(modelData && modelData.is_today)
                    color: (modelData && modelData.is_today) ? (theme ? theme.textPrimary : "#ffffff") : (theme ? theme.textSecondary : "#d1d5db")
                }

                Text {
                    id: dDate
                    x: dDay.x + root.colDayWidth + 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.colDateWidth
                    text: (modelData && modelData.date) ? modelData.date : ""
                    font.family: theme ? theme.mainFont : "sans-serif"
                    font.pixelSize: 10
                    color: theme ? theme.textMuted : "#9ca3af"
                }

                Item {
                    id: dTotal
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.colTotalWidth
                    height: parent.height

                    Text {
                        anchors.right: miniBar.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: (modelData && theme) ? theme.formatBytes(modelData.total_bytes || 0) : ""
                        font.family: theme ? theme.monoFont : "Monospace"
                        font.pixelSize: 10
                        font.bold: !!(modelData && modelData.is_today)
                        color: (modelData && modelData.is_today) ? (theme ? theme.accentWhite : "#ffffff") : (theme ? theme.textSecondary : "#d1d5db")
                        horizontalAlignment: Text.AlignRight
                    }

                    Rectangle {
                        id: miniBar
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 4
                        radius: 2
                        color: theme ? theme.bgInput : Qt.rgba(0.0, 0.0, 0.0, 0.45)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.min(parent.width, Math.max(2, parent.width * ((modelData && modelData.total_bytes ? modelData.total_bytes : 0) / Math.max(1, root.maxWeekBytes))))
                            radius: 2
                            color: (modelData && modelData.is_today) ? (theme ? theme.accentWhite : "#ffffff") : (theme ? theme.accentGrey : "#9ca3af")
                        }
                    }
                }

                Text {
                    id: dUp
                    anchors.right: dTotal.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.colUpWidth
                    text: (modelData && theme) ? theme.formatBytes(modelData.up_bytes || 0) : ""
                    font.family: theme ? theme.monoFont : "Monospace"
                    font.pixelSize: 10
                    color: theme ? theme.textSecondary : "#d1d5db"
                    horizontalAlignment: Text.AlignRight
                }

                Text {
                    id: dDown
                    anchors.right: dUp.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.colDownWidth
                    text: (modelData && theme) ? theme.formatBytes(modelData.down_bytes || 0) : ""
                    font.family: theme ? theme.monoFont : "Monospace"
                    font.pixelSize: 10
                    color: theme ? theme.textSecondary : "#d1d5db"
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
