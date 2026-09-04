pragma Singleton

import QtQuick
import Quickshell

// Nerd Font glyphs, named by what they mean rather than what they look like.
//
// They live in one place because they are the only part of the shell that
// depends on the icon font actually being the configured monospace family:
// if a glyph comes out as a box, it is fixed here.
Singleton {
    id: root

    // ── media ─────────────────────────────────────────────────────────────

    readonly property string play: "󰐊"
    readonly property string pause: "󰏤"
    readonly property string next: "󰒭"
    readonly property string previous: "󰒮"
    readonly property string music: "󰎇"

    // ── audio ─────────────────────────────────────────────────────────────

    readonly property string volumeHigh: "󰕾"
    readonly property string volumeMedium: "󰖀"
    readonly property string volumeLow: "󰕿"
    readonly property string volumeMuted: "󰝟"
    readonly property string microphone: "󰍬"
    readonly property string microphoneMuted: "󰍭"
    readonly property string speaker: "󰓃"
    readonly property string headphones: "󰋋"

    // ── bluetooth, and the kinds of device it turns up ────────────────────

    readonly property string bluetooth: "󰂯"
    readonly property string bluetoothOff: "󰂲"
    readonly property string keyboard: "󰌌"
    readonly property string mouse: "󰍽"
    readonly property string phone: "󰄜"
    readonly property string computer: "󰌢"
    readonly property string display: "󰍹"

    // ── network ────────────────────────────────────────────────────────────

    readonly property string networkOff: "󰅛"
    readonly property string wifi: "󰖩"
    readonly property string ethernet: "󰈀"
    readonly property string vpn: "󰖂"

    // ── chrome ────────────────────────────────────────────────────────────

    readonly property string back: "󰅁"
    readonly property string forward: "󰅂"
    readonly property string close: "󰅖"
    readonly property string bell: "󰂚"
    readonly property string search: "󰍉"
    readonly property string check: "󰄬"

    // The `icon` bluez hands out is a freedesktop icon name; map the ones
    // that actually show up and fall back to a plain bluetooth mark.
    function device(icon: string): string {
        switch (icon) {
        case "audio-headset":
        case "audio-headphones":
            return root.headphones;
        case "audio-card":
        case "audio-speakers":
            return root.speaker;
        case "input-keyboard":
            return root.keyboard;
        case "input-mouse":
        case "input-tablet":
            return root.mouse;
        case "phone":
            return root.phone;
        case "computer":
            return root.computer;
        case "video-display":
            return root.display;
        default:
            return root.bluetooth;
        }
    }

    // Which glyph one of `Network.kind`'s three kinds of link gets.
    function link(kind: string): string {
        switch (kind) {
        case "wireless":
            return root.wifi;
        case "tunnel":
            return root.vpn;
        default:
            return root.ethernet;
        }
    }

    // Which of the four speaker glyphs a volume deserves.
    function volume(level: real, muted: bool): string {
        if (muted || level <= 0)
            return root.volumeMuted;
        if (level < 0.34)
            return root.volumeLow;
        if (level < 0.67)
            return root.volumeMedium;
        return root.volumeHigh;
    }
}
