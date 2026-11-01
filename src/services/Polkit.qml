pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import qs.config

// The polkit agent: what answers when something on the machine wants to do
// a thing it needs a password for — install a package, restart a service,
// mount a disk — and polkit asks the session to find out whether the person
// at it may.
//
// Quickshell does the talking to polkit and to PAM. A request arrives here
// as a flow: what is being asked, the people who could say yes to it, and a
// conversation with PAM that is under way, which asks for a password, or for
// whatever else the session is set up to ask for, and says so when the
// answer was wrong. Requests that arrive while one is being answered wait
// their turn, and `flow` moves on to the next as each one is done; between
// them it is null. The pane that asks is `Prompt`.
//
// Only one agent can answer for a session, so the switch is
// `Config.polkitAgent`: off, nothing here registers, and whichever other
// agent the session runs is left to it.
Singleton {
    id: root

    // the request being answered, or null while there is none
    readonly property var flow: agent.item?.flow ?? null
    // polkit took the agent on as the session's
    readonly property bool registered: agent.item?.isRegistered ?? false

    // The answer, handed straight to the conversation. This is the only
    // place a password passes through on its way out of the field, and it
    // is held by nothing here: not bound, not stored, not logged.
    function submit(response: string): void {
        root.flow?.submit(response);
    }

    function cancel(): void {
        root.flow?.cancelAuthenticationRequest();
    }

    // Authenticate as someone else from the flow's identities instead: the
    // conversation under way is dropped and a new one started for them.
    function choose(identity: var): void {
        if (root.flow && identity)
            root.flow.selectedIdentity = identity;
    }

    LazyLoader {
        id: agent

        active: Config.polkitAgent

        PolkitAgent {}
    }
}
