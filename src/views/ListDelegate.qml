import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.3
import org.mauikit.controls 1.3 as Maui

Maui.ListBrowserDelegate
{
    id: control

    function formatSize(size)
    {
        const bytes = Number(size)

        if (!Number.isFinite(bytes) || bytes < 0)
            return ""

        if (bytes < 1024)
            return i18n("%1 B", Math.round(bytes))

        const units = ["KB", "MB", "GB", "TB"]
        let value = bytes / 1024
        let unitIndex = 0

        while (value >= 1024 && unitIndex < units.length - 1) {
            value /= 1024
            unitIndex++
        }

        return i18n("%1 %2", value.toFixed(value >= 10 ? 0 : 1), units[unitIndex])
    }

    isCurrentItem: ListView.isCurrentItem
    draggable: true
    tooltipText: model.url
    checkable: root.selectionMode
    checked: selectionBar ? selectionBar.contains(model.url) : false

    Drag.keys: ["text/uri-list"]
    Drag.mimeData: Drag.active ? {
        "text/uri-list": filterSelectedItems(model.url)
    } : {}

    label1.text: model.label
    label2.text: formatSize(model.size)
    label3.text: model.mime
    label4.text: Qt.formatDateTime(new Date(model.modified), "d MMM yyyy")

    iconSource: model.icon
    template.fillMode: Image.PreserveAspectFit
}
