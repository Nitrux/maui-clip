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

            selectionBar.insert(model.get(index))
        }
    }

    MenuItem
    {
        text: i18nc("@action:inmenu", "Show in Folder")
        icon.name: "folder-open"
        onTriggered:
        {
            //            Pix.Collection.showInFolder([control.model.get(index).url])
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
