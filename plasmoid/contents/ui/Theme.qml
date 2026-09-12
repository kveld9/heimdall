import QtQuick
import org.kde.kirigami as Kirigami

QtObject {
    id: theme

    // Toggle between Cyber Olive (from the mockups) and dynamic KDE Plasma Palette
    property bool useCyberTheme: true

    // Backgrounds
    readonly property color bgPrimary: useCyberTheme ? "#131712" : Kirigami.Theme.backgroundColor
    readonly property color bgCard: useCyberTheme ? "#1c2219" : Kirigami.Theme.cardBackgroundColor
    readonly property color bgCardHighlight: useCyberTheme ? "#242c20" : Qt.lighter(Kirigami.Theme.cardBackgroundColor, 1.15)
    readonly property color bgInput: useCyberTheme ? "#171c14" : Qt.darker(Kirigami.Theme.backgroundColor, 1.1)

    // Borders & Dividers
    readonly property color border: useCyberTheme ? "#2b3628" : Kirigami.Theme.separatorColor
    readonly property color borderSubtle: useCyberTheme ? "#1f261d" : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
    readonly property color glowGreen: useCyberTheme ? "#7ae582" : Kirigami.Theme.highlightColor

    // Accents
    readonly property color accentGreen: useCyberTheme ? "#7ae582" : Kirigami.Theme.positiveTextColor
    readonly property color accentPink: useCyberTheme ? "#ff79c6" : Kirigami.Theme.negativeTextColor
    readonly property color accentYellow: useCyberTheme ? "#f1fa8c" : Kirigami.Theme.neutralTextColor
    readonly property color accentMuted: useCyberTheme ? "#687964" : Kirigami.Theme.disabledTextColor

    // Text hierarchy
    readonly property color textPrimary: useCyberTheme ? "#e2ebd8" : Kirigami.Theme.textColor
    readonly property color textSecondary: useCyberTheme ? "#889c83" : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.65)
    readonly property color textMuted: useCyberTheme ? "#576654" : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.45)

    // Typography
    readonly property string monoFont: "Monospace"
    readonly property string mainFont: "sans-serif"

    function formatBytes(bytes) {
        if (!bytes || bytes <= 0) return "0.0 MB";
        var kb = bytes / 1024.0;
        if (kb < 1024) return kb.toFixed(1) + " KB";
        var mb = kb / 1024.0;
        if (mb < 1024) return mb.toFixed(1) + " MB";
        var gb = mb / 1024.0;
        return gb.toFixed(2) + " GB";
    }

    function formatBytesInt(bytes) {
        if (!bytes || bytes <= 0) return "0 MB";
        var mb = bytes / (1024.0 * 1024.0);
        if (mb < 1024) return Math.round(mb) + " MB";
        var gb = mb / 1024.0;
        return gb.toFixed(2) + " GB";
    }

    function formatSpeed(kb) {
        if (!kb || kb <= 0) return "0 KB/s";
        if (kb < 1024) return Math.round(kb) + " KB/s";
        var mb = kb / 1024.0;
        return mb.toFixed(1) + " MB/s";
    }
}
