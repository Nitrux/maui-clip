import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui

Maui.ContextualMenu
{
    id: control

    property int index : -1
    property Maui.BaseModel model : null

    MenuItem
    {
        text: i18nc("@action:inmenu", "Select")
        icon.name: "item-select"
        onTriggered:
        {
            if(Maui.Handy.isMobile)
                root.selectionMode = true

            const item = model ? model.get(index) : null

            if (selectionBar && item && item.url)
                selectionBar.append(item.url, item)
        }
    }

    MenuItem
    {
        text: i18nc("@action:inmenu", "Copy Path to Clipboard")
        icon.name: "edit-copy"
        onTriggered:
        {
            const item = model ? model.get(index) : null
            const path = item ? String(item.path || item.url || "") : ""

            if (path.length > 0)
                Maui.Handy.copyTextToClipboard(path)

            close()
        }
    }

    MenuSeparator{}

    MenuItem
    {
        text: i18nc("@action:inmenu", "Remove")
        icon.name: "edit-delete"
        Maui.Controls.status: Maui.Controls.Negative
        onTriggered: removeFiles([model.get(index).url])
    }
}
