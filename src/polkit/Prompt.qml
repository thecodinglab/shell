pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.util
import qs.widgets

// The polkit agent's pane: what is asking for a password, and the field to
// give it in. One for the whole shell, brought out on whichever monitor has
// focus when the request arrives, since that is where whoever set it off is
// looking.
//
// It is drawn after the password prompt on a mac, out of Spotlight's glass:
// a narrow pane floating a little above the middle of the screen, with the
// shadow and the hairline round it, and everything on it centred down one
// column. Its corners are those of the capsules on it, a page margin out.
// At its head the application's own icon with the padlock on its shoulder,
// or the padlock alone when it brought none; under it, in bold, what polkit
// says is being asked — "Authentication is required to manage system
// services or other units" — and what it wants for it: "Enter your
// password to allow this." Then who is being asked, unless it can only be
// whoever is at the machine: a name, said plainly, or a pop-up that
// opens into the list of them when polkit would take any of several. Then
// the answer, a capsule that asks whatever the conversation asks and hides
// what is typed unless it is told the answer may be seen. Under it a line
// for what PAM has to say, and at the foot Cancel and Allow, side by side
// and as wide as each other, Allow in the accent because it is what Return
// presses.
//
// Return answers and Escape gives up; a wrong answer shakes the pane, says
// so, and leaves the field empty for another go. While it is out it has the
// keyboard to itself, so nothing typed into it lands anywhere else. It is
// masked down to the pane: the desktop around it still takes the pointer.
PanelWindow {
    id: root

    // The monitor with focus, as the shell root sees it: where the pane
    // comes out when a request arrives. Read once as it opens, so focus
    // moving while it is out does not carry it off.
    property var focusedScreen: null

    property bool open: false

    // it has come out, for the shell root to put away whatever else had
    // the keyboard
    signal opened

    // The request being answered. A second one queued behind the first takes
    // its place while the pane is still out; the last one going puts it away.
    readonly property var flow: Polkit.flow

    // What the request said, kept for the pane to fade out with once the
    // flow it came from has gone.
    property string message: ""
    property string image: ""

    // the last answer was wrong, and nothing has been typed since
    property bool wrong: false
    // an answer is on its way to PAM, and nothing has come back yet
    property bool checking: false
    // the list of who else could answer is open
    property bool choosing: false

    // What PAM last had to say since the last answer went: a fingerprint
    // reader waiting, an account locked. The flow keeps its last message
    // for good, so it is heard here as it arrives and let go of as each
    // answer is sent, rather than read off the flow, or one attempt's
    // complaint would still be on the pane for the next.
    property string said: ""
    property bool saidError: false

    readonly property var identities: root.flow?.identities ?? []
    readonly property var identity: root.flow?.selectedIdentity ?? null
    readonly property bool ready: root.flow?.isResponseRequired ?? false

    // What the conversation wants, taken into the middle of a sentence the
    // way a mac asks for it: the field's "Password", in "Enter your password
    // to allow this." A word in capitals, a PIN, is left as it is.
    readonly property string wanted: /^[A-Z][a-z]/.test(response.placeholder) ? response.placeholder[0].toLowerCase() + response.placeholder.slice(1) : response.placeholder

    // everything one conversation knew, let go of before the next
    function forget(): void {
        response.clear();
        root.wrong = false;
        root.checking = false;
        root.said = "";
        root.saidError = false;
    }

    // Each request starts over: the field empty with the caret in it, the
    // list shut, nothing said yet.
    onFlowChanged: {
        root.forget();
        root.choosing = false;

        if (!root.flow) {
            root.open = false;
            return;
        }

        root.message = root.flow.message;
        root.image = root.flow.iconName ? Quickshell.iconPath(root.flow.iconName, true) : "";
        // anything PAM said before the pane was listening
        root.said = root.flow.supplementaryMessage;
        root.saidError = root.flow.supplementaryIsError;

        if (!root.open) {
            // on a monitor of its own choosing before it is mapped, so it
            // never comes out on one and moves to another; caught on its
            // way out, it turns round where it is
            if (!root.visible)
                root.screen = root.focusedScreen;
            root.open = true;
            root.opened();
        }

        response.take();
    }

    // The conversation turned round: PAM is asking again, so whatever was
    // sent has been answered.
    onReadyChanged: {
        if (root.ready)
            root.checking = false;
    }

    function submit(): void {
        if (!root.ready)
            return;

        root.wrong = false;
        root.said = "";
        root.saidError = false;
        root.checking = true;
        Polkit.submit(response.handOver());
    }

    function cancel(): void {
        response.clear();
        Polkit.cancel();
    }

    // Someone else to authenticate as: the conversation starts over for
    // them, and the keyboard goes back to the field.
    function choose(identity: var): void {
        root.choosing = false;
        root.forget();
        Polkit.choose(identity);
        response.take();
    }

    // one step back out: the list of identities, and then the request
    function dismiss(): void {
        if (root.choosing) {
            root.choosing = false;
            response.take();
        } else {
            root.cancel();
        }
    }

    Connections {
        target: root.flow

        // A new conversation is started for the same person on its own;
        // the field is empty for it, and the pane shakes its head.
        function onAuthenticationFailed(): void {
            response.clear();
            root.checking = false;
            root.wrong = true;
            shake.nudge(Theme.polkitShake);
            response.take();
            // the shake is not heard, so the words are said out loud
            status.Accessible.announce(status.text);
        }

        function onSupplementaryMessageChanged(): void {
            root.said = root.flow.supplementaryMessage;
            root.saidError = root.flow.supplementaryIsError;
        }

        function onSupplementaryIsErrorChanged(): void {
            root.saidError = root.flow.supplementaryIsError;
        }
    }

    visible: root.open || pane.visible

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusiveZone: 0
    color: "transparent"

    // what a compositor rule picks this surface out by, as Spotlight's
    // `shell-spotlight` is
    WlrLayershell.namespace: "shell-polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Region {
        id: occupied

        item: pane
    }

    mask: occupied

    // ── the pane ──────────────────────────────────────────────────────────

    // Out, 1; put away, 0, on a spring the way Spotlight comes and goes.
    Spring {
        id: appearing

        to: root.open ? 1 : 0
    }

    // ...growing and shrinking with what it carries, the list of
    // identities opening and a line from PAM arriving
    Spring {
        id: deepening

        leaf: "windows"
        enabled: pane.visible
        to: column.implicitHeight + Theme.pagePadding * 2
    }

    // ...and knocked sideways by a wrong answer, springing back to the
    // middle; with reduced motion it stays where it is
    Spring {
        id: shake

        enabled: pane.visible
        to: 0
    }

    Shadow {
        target: pane
        radius: pane.radius

        opacity: pane.opacity
        scale: pane.scale
    }

    ClippingRectangle {
        id: pane

        // glass, and everything on it drawn for glass
        objectName: Theme.paneTag

        // whole pixels, or the text on it shimmers as it moves
        x: Math.round((root.width - pane.width) / 2 + shake.value)
        y: Math.round(root.height * Theme.polkitTop)
        width: Theme.polkitWidth
        height: Math.round(deepening.value)

        // concentric with the capsules on it, a page margin in
        radius: Theme.polkitRadius
        color: Theme.pane.glass

        opacity: Math.max(0, Math.min(1, appearing.value))
        scale: Theme.polkitScale + (1 - Theme.polkitScale) * appearing.value
        visible: opacity > 0

        Accessible.role: Accessible.Dialog
        Accessible.name: "Authentication required"
        Accessible.description: root.message

        // Every key lands here once the control that has the focus has
        // passed on it: the first one turns the ring on, and escape steps
        // back out.
        FocusScope {
            anchors.fill: parent

            focus: true

            Keys.onPressed: Nav.key()
            Keys.onEscapePressed: root.dismiss()

            ColumnLayout {
                id: column

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.pagePadding

                spacing: 0

                // ── what is asked ─────────────────────────────────────────

                // The application's own icon with the padlock on its
                // shoulder, or the padlock alone when it brought none.
                Item {
                    Layout.alignment: Qt.AlignHCenter

                    implicitWidth: Theme.polkitIconSize
                    implicitHeight: Theme.polkitIconSize

                    IconImage {
                        anchors.fill: parent

                        visible: root.image !== ""

                        source: root.image
                        implicitSize: Theme.polkitIconSize
                        asynchronous: true
                    }

                    IconDisc {
                        anchors.fill: parent

                        visible: root.image === ""

                        icon: Icons.lock
                        size: Theme.polkitIconSize
                    }

                    // cut out of the sheet by a rim of the pane's ground,
                    // so it reads as laid on the icon rather than part of
                    // it; solid, where a disc on the glass is a wash, or
                    // the icon would show through the padlock
                    IconDisc {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: -Theme.polkitBadgeRim

                        visible: root.image !== ""

                        icon: Icons.lock
                        iconColor: Theme.pane.text
                        size: Theme.polkitBadgeSize + Theme.polkitBadgeRim * 2
                        color: Paint.over(Theme.pane.surface, Theme.pane.ground)

                        border.width: Theme.polkitBadgeRim
                        border.color: Theme.pane.ground
                    }
                }

                Sans {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space3

                    text: root.message || "Authentication is required."

                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }

                Caption {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space1

                    text: `Enter ${root.whose(root.identity)} ${root.wanted} to allow this.`
                    color: Theme.pane.textMuted

                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }

                // ── who is asked ──────────────────────────────────────────

                // The one whose password it wants, where a mac has the
                // user name, and only when it could be anyone but whoever
                // is at the machine: the sentence above already says
                // "your". Offering one other, it says who, as words and not
                // as a field, since there is nothing to do with it.
                Sans {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space2

                    visible: !who.choosable && text !== "" && root.whose(root.identity) !== "your"

                    text: root.nameOf(root.identity)
                    color: Theme.pane.textMuted

                    horizontalAlignment: Text.AlignHCenter

                    Accessible.name: `Authenticating as ${root.nameOf(root.identity)}`
                }

                // Polkit offering several, it is a pop-up that opens into
                // the list of them, in its place, with the keyboard on the
                // one in use.
                Rectangle {
                    id: who

                    readonly property bool choosable: root.identities.length > 1

                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space4

                    visible: who.choosable && !root.choosing

                    implicitHeight: Theme.polkitFieldHeight

                    radius: height / 2
                    color: {
                        if (whoMouse.pressed)
                            return Theme.pane.surfacePress;
                        return whoMouse.containsMouse ? Theme.pane.surfaceHover : Theme.pane.surface;
                    }

                    Behavior on color {
                        ColorFade {}
                    }

                    activeFocusOnTab: true

                    Accessible.role: Accessible.ComboBox
                    Accessible.name: `Authenticating as ${root.nameOf(root.identity)}, choose someone else`
                    Accessible.onPressAction: root.choosing = true

                    Keys.onPressed: event => {
                        Nav.key();
                        if (event.key !== Qt.Key_Space && event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)
                            return;

                        root.choosing = true;
                        event.accepted = true;
                    }

                    MouseArea {
                        id: whoMouse

                        anchors.fill: parent

                        hoverEnabled: true
                        // the arrow, as over any control; the pointing hand
                        // is for links
                        cursorShape: Qt.ArrowCursor

                        onPressed: Nav.pointer()
                        onClicked: root.choosing = true
                    }

                    // the name where the answer's words start, and the
                    // chevrons centred in the capsule's round end
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space4
                        anchors.rightMargin: Math.round((who.height - Theme.iconWidth) / 2)

                        spacing: Theme.space2

                        Sans {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            text: root.nameOf(root.identity)
                        }

                        // on the raised ground, where the dimmest ink does
                        // not read, so in the one above it
                        Caption {
                            Layout.alignment: Qt.AlignVCenter

                            visible: text !== ""

                            text: root.aboutOf(root.identity)
                            color: Theme.pane.placeholder
                        }

                        Glyph {
                            Layout.alignment: Qt.AlignVCenter

                            text: Icons.choose
                        }
                    }

                    FocusRing {
                        radius: who.radius
                    }
                }

                // ...and the list it opens into, the one in use checked the
                // way a mac checks it in a pop-up menu. Escape folds it back
                // up without choosing.
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space4 - Theme.rowPadding

                    visible: root.choosing

                    spacing: 0

                    Repeater {
                        model: root.choosing ? root.identities : []

                        delegate: ListRow {
                            id: choice

                            required property var modelData
                            required property int index

                            readonly property bool current: choice.modelData === root.identity

                            Layout.fillWidth: true

                            bleed: true
                            rule: choice.index < root.identities.length - 1
                            ruleInset: Theme.iconWidth + Theme.rowSpacing

                            Accessible.name: choice.current ? `${root.nameOf(choice.modelData)}, chosen` : root.nameOf(choice.modelData)

                            onClicked: root.choose(choice.modelData)

                            // the field the list opened from is gone, and
                            // the keyboard lands on the one it stood for
                            Component.onCompleted: {
                                if (choice.current)
                                    choice.forceActiveFocus();
                            }

                            // a column of its own, there whether or not the
                            // row is checked, so the names line up
                            Glyph {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: Theme.iconWidth

                                text: choice.current ? Icons.check : ""
                                color: Theme.pane.text
                            }

                            Label {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                title: root.nameOf(choice.modelData)
                                caption: root.aboutOf(choice.modelData)
                            }
                        }
                    }
                }

                // ── the answer ────────────────────────────────────────────

                Response {
                    id: response

                    Layout.fillWidth: true
                    // close under the pop-up it goes with, and a full gap
                    // under the words when there is no pop-up
                    Layout.topMargin: who.choosable ? Theme.space2 : Theme.space4

                    prompt: root.flow?.inputPrompt ?? ""
                    echo: root.flow?.responseVisible ?? false
                    ready: root.ready

                    onAccepted: root.submit()
                    onEdited: root.wrong = false
                }

                // What there is to say about the last answer: whatever PAM
                // had to add, in its own words; failing that, that it was
                // wrong, or that it is still being checked. Nothing to say,
                // it takes no room, and the pane grows on its spring to
                // make room for it as it comes.
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: column.width
                    Layout.topMargin: Theme.space2

                    visible: status.text !== ""

                    spacing: Theme.space2

                    Spinner {
                        Layout.alignment: Qt.AlignVCenter

                        visible: root.checking
                    }

                    Caption {
                        id: status

                        Layout.fillWidth: true

                        text: {
                            if (root.said !== "")
                                return root.said;
                            if (root.wrong)
                                return `Incorrect ${root.wanted}. Try again.`;
                            return root.checking ? "Checking…" : "";
                        }
                        color: (root.said !== "" ? root.saidError : root.wrong) ? Theme.pane.urgent : Theme.pane.textDim

                        // an alert, so a screen reader says it without the
                        // keys leaving the field
                        Accessible.role: Accessible.AlertMessage
                        Accessible.name: status.text

                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        elide: Text.ElideNone
                    }
                }

                // ── the answer, or none ───────────────────────────────────

                // side by side and as wide as each other, the default one
                // on the right where a mac puts it
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space4

                    spacing: Theme.space2

                    Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: (column.width - Theme.space2) / 2
                        implicitHeight: Theme.polkitFieldHeight

                        text: "Cancel"

                        onClicked: root.cancel()
                    }

                    Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: (column.width - Theme.space2) / 2
                        implicitHeight: Theme.polkitFieldHeight

                        text: "Allow"
                        primary: true
                        enabled: root.ready

                        onClicked: root.submit()
                    }
                }
            }
        }
    }

    // the rim of the glass, over it rather than round it, and so beside it:
    // the pane clips what it holds
    Rim {
        target: pane
        radius: pane.radius

        opacity: pane.opacity
        scale: pane.scale
        visible: pane.visible
    }

    // ── names ─────────────────────────────────────────────────────────────

    // What an identity is called: the full name when it has one, and failing
    // that the user or group name, which polkit falls back to the id for.
    function nameOf(identity: var): string {
        if (!identity)
            return "";
        return identity.displayName || identity.string || `${identity.id}`;
    }

    // ...and the line under it: the user name, when the full name was the
    // title, and the word for a group, since a group is anyone in it.
    function aboutOf(identity: var): string {
        if (!identity)
            return "";

        const login = identity.string && identity.string !== root.nameOf(identity) ? identity.string : "";
        if (identity.isGroup)
            return login ? `Group · ${login}` : "Group";
        return login;
    }

    // ...and whose answer it wants, as the sentence under the question puts
    // it: the person at the machine's own, or else an administrator's, since
    // polkit only offers anyone else when the action wants an administrator.
    function whose(identity: var): string {
        if (identity && !identity.isGroup && identity.string === Quickshell.env("USER"))
            return "your";
        return "an administrator's";
    }
}
