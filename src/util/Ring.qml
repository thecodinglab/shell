import QtQuick

// A fixed length window over the most recent samples of something, for the
// bar graphs to draw. Assigning a whole new array rather than mutating one is
// what makes `values` a usable binding source.
QtObject {
    id: root

    property int size: 40
    // newest last, so a graph drawn left to right runs oldest to newest
    property var values: []

    function push(value: real): void {
        const next = root.values.slice(Math.max(0, root.values.length - root.size + 1));
        next.push(value);
        root.values = next;
    }
}
