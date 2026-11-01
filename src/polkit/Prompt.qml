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
// It is made the way Spotlight is, out of the same glass: a pane floating a
// little above the middle of the screen, with the shadow and the hairline
// round it and the large radius. At its head the application's own icon, or
// the shield when it brought none, and what polkit says is being asked —
// "Authentication is required to manage system services or other units" —
// with the action it is asked for under it. Then who is being asked: the
// person whose password it wants, and when polkit would take any of several,
// a row that opens into the list of them. Then the field, which asks whatever
// the conversation asks and hides what is typed unless it is told the
// answer may be seen, and the line under it for what PAM has to say. At the
// foot, Cancel and Authenticate.
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
    property string action: ""
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
        root.action = root.flow.actionId;
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

        // whole pixels, or the text on it shimmers as it moves
        x: Math.round((root.width - pane.width) / 2 + shake.value)
        y: Math.round(root.height * Theme.polkitTop)
        width: Theme.polkitWidth
        height: Math.round(deepening.value)

        radius: Theme.radiusLarge
        color: Theme.glass

        border.width: 1
        border.color: Theme.glassEdge

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

                spacing: Theme.stackSpacing

                // ── what is asked ─────────────────────────────────────────

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: Theme.sectionSpacing - Theme.stackSpacing

                    spacing: Theme.rowSpacing

                    Item {
                        Layout.alignment: Qt.AlignTop

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

                            icon: Icons.shield
                            size: Theme.polkitIconSize
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        spacing: Theme.lineGap

                        Title {
                            Layout.fillWidth: true

                            text: root.message || "Authentication is required"

                            wrapMode: Text.Wrap
                            elide: Text.ElideNone
                        }

                        // the action, by the name polkit knows it by, which
                        // is the nearest it says to who is asking
                        Caption {
                            Layout.fillWidth: true

                            visible: text !== ""

                            text: root.action
                            elide: Text.ElideMiddle
                        }
                    }
                }

                // ── who is asked ──────────────────────────────────────────

                // The one whose password it wants. Polkit offering several,
                // the row opens into the list of them, in its place, with
                // the keyboard on the one in use; offering one, it is only a
                // line saying who.
                ListRow {
                    Layout.fillWidth: true

                    visible: !root.choosing

                    bleed: true
                    interactive: root.identities.length > 1

                    Accessible.name: root.identities.length > 1 ? `Authenticating as ${root.nameOf(root.identity)}, choose someone else` : `Authenticating as ${root.nameOf(root.identity)}`

                    onClicked: root.choosing = !root.choosing

                    IconDisc {
                        Layout.alignment: Qt.AlignVCenter

                        icon: root.identity?.isGroup ? Icons.group : Icons.user
                        size: Theme.discSizeSmall
                    }

                    Label {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        title: root.nameOf(root.identity)
                        caption: root.aboutOf(root.identity)
                    }

                    Glyph {
                        Layout.alignment: Qt.AlignVCenter

                        visible: root.identities.length > 1

                        text: Icons.expand
                    }
                }

                // ...and the list it opens into, the one in use checked.
                // Escape folds it back up without choosing.
                ColumnLayout {
                    Layout.fillWidth: true

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
                            ruleInset: Theme.discSizeSmall + Theme.rowSpacing

                            Accessible.name: choice.current ? `${root.nameOf(choice.modelData)}, chosen` : root.nameOf(choice.modelData)

                            onClicked: root.choose(choice.modelData)

                            // the row the list opened from is gone, and the
                            // keyboard lands on the one it stood for
                            Component.onCompleted: {
                                if (choice.current)
                                    choice.forceActiveFocus();
                            }

                            IconDisc {
                                Layout.alignment: Qt.AlignVCenter

                                icon: choice.modelData.isGroup ? Icons.group : Icons.user
                                size: Theme.discSizeSmall
                                pressed: choice.pressed
                            }

                            Label {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                title: root.nameOf(choice.modelData)
                                caption: root.aboutOf(choice.modelData)
                            }

                            Glyph {
                                Layout.alignment: Qt.AlignVCenter

                                visible: choice.current

                                text: Icons.check
                                color: Theme.text
                            }
                        }
                    }
                }

                // ── the answer ────────────────────────────────────────────

                Response {
                    id: response

                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space1

                    prompt: root.flow?.inputPrompt ?? ""
                    echo: root.flow?.responseVisible ?? false
                    ready: root.ready

                    onAccepted: root.submit()
                    onEdited: root.wrong = false
                }

                // What there is to say about the last answer: whatever PAM
                // had to add, in its own words; failing that, that it was
                // wrong, or that it is still being checked. Always a line
                // tall, so the buttons do not jump as it comes and goes.
                RowLayout {
                    Layout.fillWidth: true

                    spacing: Theme.space2

                    Spinner {
                        Layout.alignment: Qt.AlignVCenter

                        visible: root.checking
                    }

                    Caption {
                        Layout.fillWidth: true

                        text: {
                            if (root.said !== "")
                                return root.said;
                            if (root.wrong)
                                return "That was not accepted. Try again.";
                            return root.checking ? "Checking…" : "";
                        }
                        color: (root.said !== "" ? root.saidError : root.wrong) ? Theme.urgent : Theme.textDim

                        wrapMode: Text.Wrap
                        elide: Text.ElideNone
                    }
                }

                // ── the answer, or none ───────────────────────────────────

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space1

                    spacing: Theme.space2

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Cancel"

                        onClicked: root.cancel()
                    }

                    Button {
                        text: "Authenticate"
                        primary: true
                        enabled: root.ready

                        onClicked: root.submit()
                    }
                }
            }
        }
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
}
