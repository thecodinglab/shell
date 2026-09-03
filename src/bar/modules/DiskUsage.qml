import QtQuick
import qs.widgets
import qs.config
import qs.services
import qs.util

ModuleText {
    text: `${Config.diskPath}  ${Fmt.bytes(Disk.freeBytes)}`
}
