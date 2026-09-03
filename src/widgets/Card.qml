import QtQuick
import Quickshell.Widgets
import qs.theme

// A module on the slab: one layout, inset, on a ground of its own.
//
// The one material the panels are built from. A module is told from the
// slab by its wash and from the next module by the gap between them, and
// that is all the structure the surface has: no rules, no frames, no
// headings over things that already say what they are.
WrapperRectangle {
    color: Theme.surface
    radius: Theme.cardRadius
    margin: Theme.cardPadding
}
