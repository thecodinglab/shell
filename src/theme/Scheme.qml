import QtQuick

// One material's colours: a ground, an ink, the ramp of twelve steps between
// them, and every role the surface draws with, worked out from those.
//
// The shell is made of two of these — see `Theme.bezel` and `Theme.pane` —
// with the same role names, so a widget asks for `scheme.text` and gets the
// ink of whichever material it happens to be standing on.
//
// Twelve steps from the ground to the ink:
//
//   0      the ground behind everything: the ink on a filled control
//   1..3   a module, and the washes a row shows under the pointer
//   4..6   the ground under a disc, an empty track, and their hover
//   7      a workspace that exists but is not here
//   8      disabled ink, the last tier that still passes as large text
//   9..11  the three tiers of text: dim, muted, and full
QtObject {
    id: root

    // opaque: what the material is when nothing shows through it
    required property color ground
    required property color ink
    required property var steps
    // Glass rather than bezel: its ground is laid at `alpha`, and what is
    // drawn on it is washes of the ink rather than opaque steps, so a row lit
    // under the pointer lets the glass show through the way the glass lets
    // the desktop. Over a ground that is opaque the two come out the same.
    property bool translucent: false
    property real alpha: 1
    required property color accentBase
    required property color urgentBase
    // the setting that asks for harder edges and darker ink — see
    // `Config.increaseContrast`
    property bool contrastUp: false

    // the ramp, each step opaque
    readonly property var neutral: root.steps.map(t => Paint.mix(root.ground, root.ink, t))

    // Step `i` as something laid over the ground: the opaque step itself on
    // a ground that is opaque, and the ink at that step's strength on one
    // that is not, which composes to the same colour wherever the glass
    // happens to be solid.
    function wash(i: int): color {
        if (!root.translucent)
            return root.neutral[i];
        return Qt.rgba(root.ink.r, root.ink.g, root.ink.b, root.steps[i]);
    }

    // Step `i` as it comes out at worst, which is what anything that has to
    // be read on it is measured against. On glass that is the glass laid
    // over pure white if it is dark, or pure black if it is light, with no
    // blur behind it to even that out, and the wash laid over the result: so
    // an ink that passes here passes over whatever window ends up behind it.
    function seen(i: int): color {
        if (!root.translucent)
            return root.neutral[i];
        const backdrop = Paint.luminance(root.ground) > 0.5 ? "#000000" : "#ffffff";
        return Paint.over(root.wash(i), Paint.over(root.glass, backdrop));
    }

    // ── grounds ───────────────────────────────────────────────────────────

    // the fill of a surface made of this material
    readonly property color glass: Qt.rgba(root.ground.r, root.ground.g, root.ground.b, root.alpha)
    // The hairline of the ink round the edge of a pane, the way the rim of a
    // sheet of glass catches the light. Fainter on a light ground, where the
    // same strength reads as a drawn border rather than a rim.
    readonly property color edge: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, root.contrastUp ? 0.32 : (Paint.luminance(root.ground) > 0.5 ? 0.10 : 0.14))
    // the line round the open sheet that tells it from what it opens over
    readonly property color keyLine: root.neutral[root.contrastUp ? 6 : 3]

    // A module: a tile on the home page, standing on a ground of its own the
    // way the blocks of a control centre do, and the two steps it takes
    // under the pointer.
    readonly property color module: root.wash(1)
    readonly property color moduleHover: root.wash(2)
    readonly property color modulePress: root.wash(3)

    // a row has no ground until the pointer finds it
    readonly property color rowHover: root.wash(2)
    readonly property color rowPress: root.wash(3)

    // The ground of a field. It stays put when the caret lands in it: the
    // ring is what says where the keys are going.
    readonly property color field: root.wash(2)

    // the ground under a disc, a button, an empty switch — something raised
    // off the page — and the two steps it takes under the pointer
    readonly property color surface: root.wash(4)
    readonly property color surfaceHover: root.wash(5)
    readonly property color surfacePress: root.wash(6)

    // the hairline between two rows, or two sections
    readonly property color rule: root.wash(root.contrastUp ? 6 : 3)
    // the empty part of a track or a dial, and a graph's older samples
    readonly property color track: root.wash(root.contrastUp ? 6 : 4)

    // ── ink ───────────────────────────────────────────────────────────────

    // Four tiers. Hierarchy is carried by these and by weight before it is
    // carried by size. The dim tier is for the page itself and the rows on
    // it, and is never set on a surface: under a disc or a button it drops
    // below what small type needs.
    readonly property color text: root.neutral[11]
    readonly property color textMuted: root.neutral[10]
    readonly property color textDim: root.neutral[root.contrastUp ? 10 : 9]
    // disabled, and nothing that has to be read
    readonly property color textFaint: root.neutral[root.contrastUp ? 9 : 8]
    // what a field says while nothing is typed in it: read before anything
    // is, so muted rather than dim
    readonly property color placeholder: root.textMuted

    // A slider's fill is the ink itself, so a bar at half reads as a solid
    // thing rather than a coloured one; what is drawn over it is the ground.
    // The inks drawn on a fill are `inkOn` rather than `on`: QML reads a
    // property named `on` and a capital for a signal handler, and one
    // declared under such a name does not read back as what it was set to.
    readonly property color fill: root.neutral[11]
    readonly property color inkOnFill: root.neutral[0]

    // ── accent, and the one semantic colour ───────────────────────────────

    // Spent on state alone: on, here, focused, and the button Return
    // presses. Pushed toward the ink only as far as it takes to stand out.
    // The bezel is dark whatever the palette, so a light palette's accent —
    // drawn to sit on a light ground — is lifted until it reads on a lit row
    // the way text has to, which also leaves the ground readable cut out of
    // it. Glass follows the palette and its accent is only ever a fill or
    // the ring there, so it only has to stand out from the glass itself; a
    // word in it is `accentInk`.
    readonly property color accent: root.translucent ? Paint.reach(root.accentBase, root.ink, root.seen(0), 3) : Paint.reach(root.accentBase, root.ink, root.seen(2), 4.5)
    // the default button under the pointer
    readonly property color accentHover: Paint.mix(root.accent, root.text, 0.14)
    // the accent as a word or a glyph, which has to be read on a lit row
    readonly property color accentInk: Paint.reach(root.accent, root.ink, root.seen(2), 4.5)
    // a selection in a field: a wash of the accent under ink that stays as it is
    readonly property color accentSurface: Paint.mix(root.ground, root.accent, 0.16)
    // What is drawn on an accent fill: the ground, the way a hole is cut in
    // it, as long as that reads on the fill and on its hover; otherwise
    // whichever of white and black does.
    readonly property color inkOnAccent: {
        if (Paint.contrast(root.ground, root.accent) >= 4.5 && Paint.contrast(root.ground, root.accentHover) >= 4.5)
            return root.ground;
        return Paint.contrast("#ffffff", root.accent) >= Paint.contrast("#000000", root.accent) ? "#ffffff" : "#000000";
    }

    // the row Spotlight's Return will open: filled in the accent, the way a
    // selection is, and everything on it in the one ink
    readonly property color selection: root.accent
    readonly property color inkOnSelection: root.inkOnAccent

    // The palette's red, pulled a little toward the ink so it warns without
    // shouting, and further if it would not read on a lit row; and the wash
    // and hairline an urgent surface is drawn with.
    readonly property color urgent: Paint.reach(Paint.mix(root.urgentBase, root.ink, 0.12), root.ink, root.seen(2), 4.5)
    readonly property color urgentSurface: Paint.mix(root.ground, root.urgent, 0.14)
    readonly property color urgentBorder: Paint.mix(root.ground, root.urgent, 0.32)

    // a workspace that exists but is not focused, filled; one that does not
    // exist yet is a ring of the same
    readonly property color dotOccupied: root.neutral[root.contrastUp ? 8 : 7]

    // What lights while the microphone, the camera or the screen is in use —
    // see `Privacy`. The accent, on purpose. A mac has an orange dot for the
    // microphone and a green one for the camera, which would be two more
    // accents here; and what the dot says is that something is on — the
    // microphone open, the camera live — which is what the accent already
    // says on a lit disc. Not the red: the red is for what has gone wrong or
    // is waiting on an answer, and a call you started is neither, and it
    // would be crying wolf for the length of every meeting. Which of the
    // three it is the page says in words, not the dot in a hue.
    readonly property color privacy: root.accent
}
