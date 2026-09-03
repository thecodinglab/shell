import QtQuick
import QtQuick.Effects
import qs.theme

// The shadow a floating surface casts on the desktop behind it.
//
// Nothing frames the shell: it opens over whatever windows happen to be
// there, and against a window of much the same colour its edge is only the
// hairline border. The shadow is what tells the two apart.
//
// Two of them, because one cannot do both jobs. The wide one carries most of
// the distance and says the surface is above the desktop; the tight one sits
// close under the bottom edge and gives that edge something to land on, so
// the slab reads as resting on the window rather than hovering somewhere
// unspecified over it.
//
// It fills `target`, which is either this item's parent — it is drawn behind
// it, so a surface gets a shadow by declaring one as its own child — or a
// sibling, for a surface that clips its children and would cut it off.
Item {
    id: root

    required property Item target
    property real radius: 0

    anchors.fill: root.target

    // behind the surface it belongs to
    z: -1

    RectangularShadow {
        anchors.fill: parent

        radius: root.radius
        blur: Theme.shadowBlur
        offset: Qt.vector2d(0, Theme.shadowOffset)
        color: Theme.shadow
    }

    RectangularShadow {
        anchors.fill: parent

        radius: root.radius
        blur: Theme.shadowContactBlur
        offset: Qt.vector2d(0, Theme.shadowContactOffset)
        color: Theme.shadowContact
    }
}
