import QtQuick
import qs.widgets
import qs.services

ModuleText {
    text: {
        switch (Network.state) {
        case "connected":
            return `󰛳   ${Network.address}`;
        case "linked":
            return "󰅛   (no ip)";
        default:
            return "󰅛 ";
        }
    }
}
