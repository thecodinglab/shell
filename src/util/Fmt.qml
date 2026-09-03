pragma Singleton

import QtQuick
import Quickshell

// Number formatting that matches what waybar printed, so the bar reads
// exactly the same as it did before.
Singleton {
    id: root

    // waybar's `pow_format(value, "B", binary = true)`: divide by 1024 until
    // the value fits, then print one decimal followed by the binary prefix.
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

    // waybar's memory module rounds to two decimals and then prints the
    // float, so trailing zeros disappear: 41.76, 41.7, 41.
    function gibibytes(kilobytes: real): string {
        // 10485.76 = 1024^2 / 100, i.e. two decimals of a GiB
        return String(Math.round(kilobytes / 10485.76) / 100);
    }
}
