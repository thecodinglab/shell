import QtQuick
import qs.theme

// The rim of a pane of glass: a hairline of the ink round its edge, the way
// the edge of a sheet of glass catches the light, so it holds its edge
// against a window of its own colour.
//
// Drawn over the glass rather than as its border. A rectangle lays its border
// beside its fill rather than on top of it, so the border of a pane that is
// not quite opaque is laid straight over the desktop, and on a light one
// all but disappears; on top of the fill, it is a line of the glass.
//
// It fills `target`, which is either this item's parent — declared last, so
// it is drawn over everything else on it — or a sibling declared after it,
// for a surface that clips its children and would cut it off.
Rectangle {
    id: root

    required property Item target
    // the target's own material, whichever side of it this is declared on
    property Scheme scheme: Theme.schemeOf(root.target)

    anchors.fill: root.target

    color: "transparent"

    border.width: 1
    border.color: root.scheme.edge
}
