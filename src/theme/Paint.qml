pragma Singleton

import QtQuick
import Quickshell

// The arithmetic colours are made with: mixing two, measuring one, and
// pushing one until it can be read. Kept apart from Theme so a Scheme can be
// built out of these while Theme, which holds the schemes, is still being
// built itself.
Singleton {
    id: root

    // `t` of the way from `a` to `b`
    function mix(a: color, b: color, t: real): color {
        const x = Qt.color(a);
        const y = Qt.color(b);
        return Qt.rgba(x.r + (y.r - x.r) * t, x.g + (y.g - x.g) * t, x.b + (y.b - x.b) * t, x.a + (y.a - x.a) * t);
    }

    // `c` with none of it showing: what a ground that only appears under the
    // pointer is while it is not there, so that it fades in as itself rather
    // than out of a transparent black
    function clear(c: color): color {
        const q = Qt.color(c);
        return Qt.rgba(q.r, q.g, q.b, 0);
    }

    // `c` laid over an opaque `bg`: what is on screen where one shows through
    // the other, which is what a translucent colour has to be measured as
    function over(c: color, bg: color): color {
        const x = Qt.color(c);
        const y = Qt.color(bg);
        return Qt.rgba(x.r * x.a + y.r * (1 - x.a), x.g * x.a + y.g * (1 - x.a), x.b * x.a + y.b * (1 - x.a), 1);
    }

    // relative luminance, the way the contrast rules measure it
    function luminance(c: color): real {
        const q = Qt.color(c);
        const lin = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * lin(q.r) + 0.7152 * lin(q.g) + 0.0722 * lin(q.b);
    }

    // How far apart two colours are to the eye, as the contrast rules count
    // it: 1 for the same colour, 21 for black on white. Both are taken as
    // opaque; a wash is measured by what it composes to, not by itself.
    function contrast(a: color, b: color): real {
        const la = root.luminance(a);
        const lb = root.luminance(b);
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }

    // `c`, pushed toward `toward` a twentieth at a time until it stands out
    // from `bg` by `ratio`: a palette's own colour where it already does, and
    // only as much less of it as it takes where it does not. All the way to
    // `toward` if nothing short of it will do.
    function reach(c: color, toward: color, bg: color, ratio: real): color {
        for (let i = 0; i <= 20; i++) {
            const candidate = root.mix(c, toward, i / 20);
            if (root.contrast(candidate, bg) >= ratio)
                return candidate;
        }
        return Qt.color(toward);
    }
}
