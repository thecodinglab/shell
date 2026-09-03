pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Colors and metrics, derived from the palette in Config.
//
// The numbers here are the ones the old waybar css resolved to at scale 1:
// a 42px bar made of three 26px tall pills inset by 8px, 20px between
// modules, 2px of breathing room around each module's text.
Singleton {
    id: root

    readonly property color background: Config.base00
    readonly property color foreground: Config.base05

    readonly property color workspaceActive: shade(Config.base0D, 0.5)
    readonly property color workspaceUrgent: shade(Config.base08, 0.5)

    readonly property string fontFamily: Config.fontFamily

    // Pango sized text in fractional pixels: 10pt at 96dpi is 13.333px, and
    // JetBrains Mono's 0.6em cell came out at exactly 8px. Qt rounds the
    // pixel size down to 13, which makes every string ~2.5% narrower than it
    // used to be. Keep the rounded size Qt insists on, then widen the letter
    // spacing by the fraction that was lost so a character cell is the same
    // width it was under waybar.
    readonly property int fontPixelSize: Math.round(root.targetPixelSize)
    readonly property real letterSpacing: metrics.advanceWidth("0") * (root.targetPixelSize - root.fontPixelSize) / root.fontPixelSize

    readonly property real targetPixelSize: Config.fontSize * 96 / 72

    FontMetrics {
        id: metrics

        font.family: root.fontFamily
        font.pixelSize: root.fontPixelSize
    }

    // ── metrics ───────────────────────────────────────────────────────────

    readonly property int barHeight: 42
    readonly property int groupHeight: 26
    readonly property int groupMargin: 8
    readonly property int groupRadius: 8

    // horizontal padding inside the center/right pills; the workspace pill
    // has none, its buttons carry their own
    readonly property int groupPadding: 8
    // gap between two modules of the same group
    readonly property int moduleSpacing: 20
    // breathing room around a module's text
    readonly property int modulePadding: 2

    readonly property int workspacePadding: 8
    // gtk buttons never got narrower than this, and single digit workspaces
    // relied on it to line up
    readonly property int workspaceMinWidth: 32

    // ── helpers ───────────────────────────────────────────────────────────

    // Reimplementation of gtk's css `shade()`, which the waybar stylesheet
    // used for the active and urgent workspace backgrounds: scale both
    // lightness and saturation by `factor` in HSL space.
    function shade(color: color, factor: real): color {
        const c = Qt.color(color);
        const max = Math.max(c.r, c.g, c.b);
        const min = Math.min(c.r, c.g, c.b);

        let h = 0;
        let s = 0;
        const l = (max + min) / 2;

        if (max !== min) {
            const d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);

            if (max === c.r)
                h = (c.g - c.b) / d + (c.g < c.b ? 6 : 0);
            else if (max === c.g)
                h = (c.b - c.r) / d + 2;
            else
                h = (c.r - c.g) / d + 4;

            h /= 6;
        }

        return Qt.hsla(h, Math.min(s * factor, 1), Math.min(l * factor, 1), c.a);
    }
}
