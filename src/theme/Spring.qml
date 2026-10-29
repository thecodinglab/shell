import QtQuick

// A number that follows `to` on a spring, the way hyprland moves a window.
//
// Bound to where something should be rather than put on the property as a
// Behavior: `x: knob.value`, with `Spring { id: knob; to: ... }` beside it.
// The difference is what happens when it is sent somewhere new while it is
// still on its way. A fixed-length animation stops dead and sets off again
// from rest, which is the hitch you see when a control is pressed and let go
// quickly, or the notch is reached for and left; a spring carries the speed
// it already has into the new target, so the two read as one gesture.
//
// The spring is solved exactly rather than stepped, the same way hyprland's
// is, for however long each frame actually took — so it moves the same at
// any refresh rate and through a dropped frame. It stops where hyprland
// stops one: within a thousandth of the distance it set out to cover, at
// a thousandth of that distance a second.
//
// `leaf` is the animation it is, by the name it has in `Config.animations`.
// With reduced motion it goes straight to `to`, and so does a new `to` while
// `enabled` is unset; a run already under way when it is unset is finished.
//
// `visible` is whether anybody can see what it moves, bound to the item it
// is moving. Unseen it goes straight to `to`, and a run under way when it is
// hidden stops where it was headed: a spring on a page nobody is looking at
// is a window drawing frames for nothing, and on every monitor at once.
QtObject {
    id: root

    property real to: 0
    property string leaf: "windowsMove"
    property bool enabled: true
    property bool visible: true

    // Where it is, and how fast it is going, in units a second. Read them;
    // only the spring writes them.
    property real value: 0
    property real velocity: 0

    readonly property bool moving: root.frames.running

    // the distance the current run set out to cover, which is what being
    // close enough to stop is measured against
    property real span: 0

    // it has come to rest at `to`
    signal arrived

    property FrameAnimation frames: FrameAnimation {
        onTriggered: root.step(root.frames.frameTime)
    }

    // straight there, with nothing left to settle
    function jump(): void {
        root.frames.stop();
        root.value = root.to;
        root.velocity = 0;
        root.arrived();
    }

    // Knock it moving at `speed`, in units a second, without changing where
    // it is going: it swings out and springs back. Knocked again on the way,
    // the two add up.
    function nudge(speed: real): void {
        if (!root.enabled || !root.visible || Theme.motion === 0 || !Theme.spring(root.leaf))
            return;

        root.velocity += speed;
        // measured by how far a knock like this carries it, roughly
        root.span = Math.max(Math.abs(root.to - root.value), Math.abs(speed) / 10);
        if (!root.frames.running)
            root.frames.start();
    }

    function step(dt: real): void {
        const spring = Theme.spring(root.leaf);
        if (!spring || Theme.motion === 0) {
            root.jump();
            return;
        }
        if (dt <= 0)
            return;

        const mass = Math.max(spring.mass ?? 1, 0.0001);
        const stiffness = Math.max(spring.stiffness, 0.0001);
        const damping = Math.max(spring.dampening, 0);

        const x = root.value - root.to;
        const v = root.velocity;
        const omega = Math.sqrt(stiffness / mass);
        const gamma = damping / (2 * mass);

        let nx;
        let nv;
        if (gamma < omega) {
            // underdamped: it swings past and back, dying away
            const omegaD = Math.sqrt(omega * omega - gamma * gamma);
            const e = Math.exp(-gamma * dt);
            const sin = Math.sin(omegaD * dt);
            const cos = Math.cos(omegaD * dt);
            nx = e * (x * cos + (v + gamma * x) / omegaD * sin);
            nv = e * (v * cos - (gamma * v + omega * omega * x) / omegaD * sin);
        } else if (Math.abs(gamma - omega) <= Math.max(omega, 1) * 0.0001) {
            // critically damped: as quick as it can be without swinging
            const e = Math.exp(-gamma * dt);
            const b = v + gamma * x;
            nx = e * (x + b * dt);
            nv = e * (v - gamma * b * dt);
        } else {
            // overdamped: it creeps in
            const root2 = Math.sqrt(gamma * gamma - omega * omega);
            const r1 = -gamma + root2;
            const r2 = -gamma - root2;
            const a = (v - r2 * x) / (r1 - r2);
            const b = x - a;
            const e1 = Math.exp(r1 * dt);
            const e2 = Math.exp(r2 * dt);
            nx = a * e1 + b * e2;
            nv = a * r1 * e1 + b * r2 * e2;
        }

        const epsilon = 0.001 * root.span;
        if (Math.abs(nx) <= epsilon && Math.abs(nv) <= epsilon) {
            root.jump();
            return;
        }

        root.value = root.to + nx;
        root.velocity = nv;
    }

    onToChanged: {
        if (!root.enabled || !root.visible || Theme.motion === 0 || !Theme.spring(root.leaf)) {
            root.jump();
            return;
        }

        // sent back to exactly where it is while it is still moving, it
        // measures by the run it was on, or it would never be close enough
        root.span = Math.abs(root.to - root.value) || root.span || 1;
        if (!root.frames.running)
            root.frames.start();
    }

    onVisibleChanged: {
        if (!root.visible && root.frames.running)
            root.jump();
    }

    Component.onCompleted: {
        root.value = root.to;
        root.velocity = 0;
    }
}
