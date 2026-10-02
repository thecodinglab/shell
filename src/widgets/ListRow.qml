import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.util

// A row in a list, or a tile on the home page: something you can press, laid
// out left to right.
//
// It has no ground until the pointer finds it, so a list is a column of names
// rather than a stack of boxes; what separates it from the next row is the
// hairline along its bottom edge. `bleed` reaches the row out past the page
// margin by its own padding, so the words inside it stay on the grid while
// the ground that lights up under the pointer wraps them.
Rectangle {
    id: root

    default property alias content: layout.data

    property bool interactive: true
    property int padding: Theme.rowPadding
    property bool bleed: false
    // the hairline: every row of a list but the last one
    property bool rule: false
    // ...inset from the left by this much, so it starts under the name
    // rather than under the disc beside it
    property int ruleInset: 0

    // something inside the row — a button of its own — has the pointer, and
    // the row keeps its ground while it does
    property bool held: false
    // the row a field above the list has stepped to: what Return will press
    property bool selected: false

    // the row is lit, whichever of the three lit it
    readonly property bool hovered: mouse.containsMouse || root.held || root.selected

    signal clicked

    Layout.leftMargin: root.bleed ? -root.padding : 0
    Layout.rightMargin: root.bleed ? -root.padding : 0

    implicitWidth: layout.implicitWidth + root.padding * 2
    implicitHeight: layout.implicitHeight + root.padding * 2

    radius: Theme.radiusSmall

    color: {
        if (!root.interactive)
            return "transparent";
        if (mouse.pressed)
            return Theme.rowPress;
        if (root.hovered)
            return Theme.rowHover;
        return "transparent";
    }

    activeFocusOnTab: root.interactive

    Accessible.role: root.interactive ? Accessible.Button : Accessible.ListItem
    Accessible.onPressAction: root.clicked()

    Keys.onPressed: event => {
        Nav.key();
        if (event.key !== Qt.Key_Space && event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)
            return;

        root.clicked();
        event.accepted = true;
    }

    // a row that has been tabbed to in a list that scrolls is brought into
    // view, which the list does not do on its own
    onActiveFocusChanged: {
        const view = root.ListView.view;
        if (!root.activeFocus || !view)
            return;

        view.positionViewAtIndex(view.indexAt(root.x + 1, root.y + 1), ListView.Contain);
    }

    // Under the content, so a button inside the row — a cross, a switch —
    // gets its click first, and only a click on the rest of the row is a
    // click on the row.
    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: Nav.pointer()
        onClicked: root.clicked()
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: root.padding

        spacing: Theme.rowSpacing
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.padding + root.ruleInset
        anchors.rightMargin: root.padding

        visible: root.rule

        height: 1
        color: Theme.rule
    }

    FocusRing {
        radius: root.radius
    }
}
