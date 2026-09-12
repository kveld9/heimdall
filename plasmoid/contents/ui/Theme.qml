import QtQuick

QtObject {
    id: theme

    // Pure Dark Violet / Lavender Theme ("todo violetita")
    // Deep obsidian-violet backgrounds
    readonly property color bgPrimary: "#120f1d"          // Deep obsidian violet
    readonly property color bgCard: "#1a162b"             // Dark violet card
    readonly property color bgCardHighlight: "#251f3d"    // Highlighted card surface
    readonly property color bgInput: "#161324"            // Inset dark violet

    // Violet Borders & Dividers
    readonly property color border: "#3b305d"             // Crisp medium violet border
    readonly property color borderSubtle: "#272040"       // Subtle deep border
    readonly property color glowViolet: "#c084fc"

    // Violet & Lavender Accents
    readonly property color accentViolet: "#c084fc"       // Radiant bright violet
    readonly property color accentLavender: "#e9d5ff"     // Soft bright lavender
    readonly property color accentPurple: "#a855f7"       // Rich neon purple
    readonly property color accentRoseViolet: "#f472b6"   // Rose-tinted violet
    readonly property color accentMuted: "#796e9c"        // Muted purple-grey
    readonly property color accentYellow: "#fcd34d"

    // Mapped aliases so all existing references turn violetita:
    readonly property color accentGreen: "#c084fc"        // Radiant violet for primary/speed/knob highlights
    readonly property color accentPink: "#e9d5ff"         // Soft lavender for secondary/download highlights

    // Text hierarchy
    readonly property color textPrimary: "#f5f3ff"       // Bright lavender-white
    readonly property color textSecondary: "#c4b5fd"     // Soft light violet
    readonly property color textMuted: "#8879a8"         // Dim violet-grey

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
