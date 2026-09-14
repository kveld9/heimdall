import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property var theme
    property var model: []
    property string emptyText: "Scanning processes..."
    property var getSecondaryText: null
    property var getPrimaryText: null
    property real secondaryWidth: 70
    property real primaryWidth: 60

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: root.model && root.model.length > 0 ? (root.model.length * 34 + 8) : 280
    color: theme ? theme.bgCardHighlight : "#16181c"
    radius: 8
    border.color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)
    border.width: 1
    clip: true

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: 4
        interactive: contentHeight > height
        model: root.model
        spacing: 0
        clip: true

        delegate: Item {
            id: rowItem
            width: listView.width
            height: 34

            // Subtle bottom separator line (except on the last element)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: theme ? theme.bgTableSeparator : Qt.rgba(1.0, 1.0, 1.0, 0.04)
                visible: index < (root.model ? (root.model.length - 1) : 7)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                // Column 1: Index (fixed width 24 px, dimmed text)
                Text {
                    text: (index + 1) + "."
                    font.family: theme ? theme.monoFont : "Monospace"
                    font.pixelSize: 11
                    color: theme ? theme.textDim : "#666666"
                    Layout.preferredWidth: 24
                }

                // Column 2: Process name (fillWidth, elide right)
                Text {
                    text: (modelData && modelData.name) ? modelData.name : (model && model.name ? model.name : "")
                    font.family: theme ? theme.monoFont : "Monospace"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: theme ? theme.textSecondary : "#e0e0e0"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Column 3: Thread/instance badge (fixed width 36 px, centered)
                Item {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 18

                    Rectangle {
                        anchors.centerIn: parent
                        visible: {
                            var inst = (modelData && modelData.instances !== undefined) ? modelData.instances :
                                       ((model && model.instances !== undefined) ? model.instances :
                                       ((model && model.threads !== undefined) ? model.threads : 1));
                            return inst > 1;
                        }
                        width: 32
                        height: 18
                        radius: 4
                        color: theme ? theme.bgTableRowHover : Qt.rgba(1.0, 1.0, 1.0, 0.05)
                        border.color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)

                        Text {
                            anchors.centerIn: parent
                            text: {
                                var inst = (modelData && modelData.instances !== undefined) ? modelData.instances :
                                           ((model && model.instances !== undefined) ? model.instances :
                                           ((model && model.threads !== undefined) ? model.threads : 1));
                                return "x" + inst;
                            }
                            font.family: theme ? theme.monoFont : "Monospace"
                            font.pixelSize: 10
                            color: theme ? theme.textMuted : "#888888"
                        }
                    }
                }

                // Column 4: Secondary metric (fixed width, elide right)
                Text {
                    text: root.getSecondaryText ? root.getSecondaryText(modelData || model, index) : ""
                    font.family: theme ? theme.monoFont : "Monospace"
                    font.pixelSize: 11
                    color: theme ? theme.textMuted : "#888888"
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    Layout.preferredWidth: root.secondaryWidth
                }

                // Column 5: Primary metric (fixed width, soft accent pill, bold text, clipped)
                Rectangle {
                    Layout.preferredWidth: root.primaryWidth
                    Layout.preferredHeight: 20
                    radius: 4
                    color: theme ? theme.bgPill : Qt.rgba(1.0, 1.0, 1.0, 0.08)
                    border.color: theme ? theme.borderSubtle : Qt.rgba(1.0, 1.0, 1.0, 0.06)
                    Layout.alignment: Qt.AlignRight
                    clip: true

                    Text {
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.width - 6)
                        text: root.getPrimaryText ? root.getPrimaryText(modelData || model, index) : ""
                        font.family: theme ? theme.monoFont : "Monospace"
                        font.pixelSize: 11
                        font.bold: true
                        color: theme ? theme.accentWhite : "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !root.model || root.model.length === 0
        text: root.emptyText
        font.family: theme ? theme.monoFont : "Monospace"
        font.pixelSize: 11
        color: theme ? theme.textMuted : "#9ca3af"
    }
}
