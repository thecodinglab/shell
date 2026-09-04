import QtQuick
import QtQuick.Layouts
import qs.theme

// What a panel says when it has nothing to list: one quiet line, inset to
// where the rows would have started.
Sans {
    Layout.fillWidth: true
    Layout.margins: Theme.cardPadding

    color: Theme.textDim
}
