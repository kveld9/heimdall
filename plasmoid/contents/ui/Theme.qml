import QtQuick

QtObject {
    id: theme

    // Pure Monochromatic Translucent Window-Manager (WM) Aesthetic
    // Translucent dark glass backgrounds
    readonly property color bgPrimary: Qt.rgba(0.04, 0.04, 0.05, 0.70)          // Smoked dark glass (translucent)
    readonly property color bgCard: Qt.rgba(1.0, 1.0, 1.0, 0.04)                // Frosted glass card
    readonly property color bgCardHighlight: Qt.rgba(1.0, 1.0, 1.0, 0.08)       // Elevated glass surface
    readonly property color bgInput: Qt.rgba(0.0, 0.0, 0.0, 0.45)               // Recessed dark track

    // Crisp Monochromatic Borders
    readonly property color border: Qt.rgba(1.0, 1.0, 1.0, 0.12)                // Crisp translucent white border
    readonly property color borderSubtle: Qt.rgba(1.0, 1.0, 1.0, 0.06)          // Subtle inner divider
    readonly property color glowMonochrome: Qt.rgba(1.0, 1.0, 1.0, 0.25)

    // Monochromatic Accents
    readonly property color accentWhite: "#ffffff"                               // High-contrast pure white
    readonly property color accentSilver: "#e5e7eb"                              // Crisp silver
    readonly property color accentGrey: "#9ca3af"                                // Neutral metallic grey
    readonly property color accentDarkGrey: "#374151"                            // Deep slate/charcoal
    readonly property color accentMuted: "#6b7280"                               // Dim neutral grey

    // Aliases mapped to monochrome
    readonly property color accentGreen: "#ffffff"                               // Pure white for primary highlights & knobs
    readonly property color accentPink: "#9ca3af"                                // Crisp silver-grey for secondary/downloads
    readonly property color accentViolet: "#ffffff"                              // Pure white
    readonly property color accentLavender: "#e5e7eb"                            // Bright silver
    readonly property color accentWarn: "#ffffff"                                // High-contrast pure white for warnings in monochrome
    readonly property color accentAlert: "#ffffff"                               // High-contrast pure white for critical states

    // High-Contrast Text hierarchy
    readonly property color textPrimary: "#ffffff"                              // High-contrast pure white
    readonly property color textSecondary: "#d1d5db"                            // Crisp readable light silver
    readonly property color textMuted: "#9ca3af"                                // Clear readable medium grey
    readonly property color textDim: "#6b7280"                                  // Dim label grey

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
