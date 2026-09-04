pragma Singleton

import QtQuick
import Quickshell

// Number formatting shared by the panels, so a byte count reads the same
// wherever it turns up.
Singleton {
    id: root

    // Divide by 1024 until the value fits, then print one decimal followed by
    // the binary prefix: 312.4GiB.
    function bytes(value: real): string {
        const units = ["", "k", "M", "G", "T", "P"];

        let fraction = value;
        let pow = 0;
        while (pow + 1 < units.length && fraction / 1024 >= 1) {
            fraction /= 1024;
            pow += 1;
        }

        const prefix = units[pow] + (pow > 0 ? "i" : "");
        return `${fraction.toFixed(1)}${prefix}B`;
    }

    // Track positions, mpris style: 1:47, or 1:02:03 once it passes an hour.
    function duration(seconds: real): string {
        if (!isFinite(seconds) || seconds < 0)
            return "0:00";

        const total = Math.floor(seconds);
        const s = total % 60;
        const m = Math.floor(total / 60) % 60;
        const h = Math.floor(total / 3600);

        const pad = n => String(n).padStart(2, "0");
        return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${m}:${pad(s)}`;
    }

    // How long something covers, in the coarsest unit that still says
    // something: 80s, 3m, 2h. Unlike `duration` this is a length of time
    // rather than a position in one, so it never reads as a clock.
    function span(seconds: real): string {
        if (!isFinite(seconds) || seconds <= 0)
            return "0s";
        if (seconds < 120)
            return `${Math.round(seconds)}s`;
        if (seconds < 7200)
            return `${Math.round(seconds / 60)}m`;
        return `${Math.round(seconds / 3600)}h`;
    }

    // How long ago something happened, the way a list of things that happened
    // says it: now, 5m ago, 2h ago, 3d ago. Coarse on purpose — it is read
    // down a column, and "47 minutes ago" is a figure where "47m ago" is a
    // glance. Both ends are milliseconds since the epoch.
    function ago(then: real, now: real): string {
        const seconds = Math.max(0, (now - then) / 1000);
        if (seconds < 60)
            return "now";
        if (seconds < 3600)
            return `${Math.floor(seconds / 60)}m ago`;
        if (seconds < 86400)
            return `${Math.floor(seconds / 3600)}h ago`;
        return `${Math.floor(seconds / 86400)}d ago`;
    }

    // A 0..1 fraction as a whole percentage, truncated rather than rounded so
    // nothing ever reads 100% while it is still climbing.
    function percent(fraction: real): string {
        return `${Math.trunc((fraction || 0) * 100)}%`;
    }
}
