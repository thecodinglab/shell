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

    // Two decimals with the trailing zeros stripped: 41.76, 41.7, 41.
    function gibibytes(kilobytes: real): string {
        // 10485.76 = 1024^2 / 100, i.e. two decimals of a GiB
        return String(Math.round(kilobytes / 10485.76) / 100);
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

    // A 0..1 fraction as a whole percentage, truncated rather than rounded so
    // nothing ever reads 100% while it is still climbing.
    function percent(fraction: real): string {
        return `${Math.trunc((fraction || 0) * 100)}%`;
    }
}
