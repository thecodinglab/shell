import QtQuick
import QtQuick.Effects
import qs.theme

// The shadow a floating surface casts on the desktop behind it.
//
// Nothing frames the shell: it opens over whatever windows happen to be
// there, and against a window of much the same colour its edge is only the
// hairline border. The shadow is what tells the two apart.
//
// It fills `target`, which is either this item's parent — it is drawn behind
// it, so a surface gets a shadow by declaring one as its own child — or a
// sibling, for a surface that clips its children and would cut it off.
RectangularShadow {
    id: root

    required property Item target

    anchors.fill: root.target

    // behind the surface it belongs to
    z: -1

    blur: Theme.shadowBlur
    offset: Qt.vector2d(0, Theme.shadowOffset)
    color: Theme.shadow
}
