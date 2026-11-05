import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.theme
import qs.services
import qs.widgets

// A bluetooth device connecting, disconnecting, or done doing either, for a
// moment under the top edge — `bluetoothctl connect` has nothing to show for
// the seconds a headset takes to answer, and this is it.
//
// The same capsule of glass as the volume reading, dropping out from under
// the top edge: the glyph for the kind of device, its name, and the line
// under it on what is happening — see `Bt.news`. While bluez is still
// working on it, a spinner turns at the trailing end and the capsule stays
// out however long that takes; once the device has settled it says what
// came of it and goes back up a moment and a half later.
//
// It takes no clicks, for the same reason the volume reading takes none.
Rectangle {
    id: root

    // the device being announced, and whether its connection failed
    property BluetoothDevice device: null
    property bool failed: false
    // kept from going out — the notch is open and says it already
    property bool suppressed: false

    readonly property bool busy: Bt.busy(root.device)

    // whether it is out, and the cue for anything under it to make room
    readonly property bool shown: !root.suppressed && root.device !== null && (root.busy || hold.running)
    // how far off the top edge it is, as a fraction of its own height — see Osd
    readonly property alias slide: sliding.value

    // Bring it out on `device`, or keep it out: every call restarts the clock.
    function show(device: BluetoothDevice, failed: bool): void {
        root.device = device;
        root.failed = failed;
        hold.restart();
    }

    // glass, so what is drawn on it takes the pane's colours
    objectName: Theme.paneTag

    implicitWidth: Theme.osdWidth
    implicitHeight: row.implicitHeight + Theme.osdPadding * 2

    radius: height / 2
    color: Theme.pane.glass

    opacity: Math.max(0, Math.min(1, 1 - root.slide))
    visible: opacity > 0

    Spring {
        id: sliding

        to: root.shown ? 0 : 1
    }

    Shadow {
        target: root
        radius: root.radius
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: Theme.osdPadding + Theme.space1
        anchors.rightMargin: Theme.osdPadding + Theme.space1
        anchors.topMargin: Theme.osdPadding
        anchors.bottomMargin: Theme.osdPadding

        spacing: Theme.rowSpacing

        Glyph {
            Layout.alignment: Qt.AlignVCenter

            text: Icons.device(root.device?.icon ?? "")
            color: Theme.pane.text

            font.pixelSize: Theme.fontTitle
        }

        Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            title: Bt.label(root.device)
            caption: Bt.news(root.device, root.failed)
            // muted, the figure's ink on the volume reading: glass is a
            // surface, and the dim tier is for the page
            captionColor: Theme.pane.textMuted
        }

        Spinner {
            Layout.alignment: Qt.AlignVCenter

            visible: root.busy
        }
    }

    Timer {
        id: hold

        interval: Theme.osdHold
    }

    Rim {
        target: root
        radius: root.radius
    }
}
