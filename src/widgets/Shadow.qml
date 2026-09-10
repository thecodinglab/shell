import QtQuick
import QtQuick.Effects
import qs.theme

// The shadow a floating surface casts on the desktop behind it: the slab, a
// toast, the volume reading. Nothing on the sheet itself casts one.
//
// Nothing frames the shell: it opens over whatever windows happen to be
// there, and against a window of much the same colour its edge is only the
// hairline. The shadow is what tells the two apart.
//
// It fills `target`, which is either this item's parent — it is drawn behind
// it, so a surface gets a shadow by declaring one as its own child — or a
// sibling, for a surface that clips its children and would cut it off.
RectangularShadow {
    required property Item target

    anchors.fill: target

    // behind the surface it belongs to
    z: -1

    blur: Theme.shadowBlur
    offset: Qt.vector2d(0, Theme.shadowOffset)
    color: Theme.shadow
}
