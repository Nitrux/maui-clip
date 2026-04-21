import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

Maui.ContextualMenu
{
    id: control

    property bool isFav : false
    property int index : -1
    property Maui.BaseModel model : null

    onOpened: control.isFav = FB.Tagging.isFav(control.model.get(index).url)


    Maui.MenuItemActionRow
    {
        Action
        {
            text: i18n(isFav ? "UnFav it": "Fav it")
            icon.name: "love"
            onTriggered: FB.Tagging.toggleFav(control.model.get(index).url)
        }

        Action
        {
            text: i18n("Tags")
            icon.name: "tag"
            onTriggered: tagFiles([control.model.get(index).url])
        }

        Action
        {
            text: i18n("Info")
            icon.name: "documentinfo"
            onTriggered:
            {
                getFileInfo(control.model.get(index).url)
                close()
            }
        }

        Action
        {
            text: i18n("Share")
            icon.name: "document-share"
            onTriggered:
            {
                Maui.Platform.shareFiles([control.model.get(index).url])
            }
        }
    }

    MenuItem
    {
        text: i18n("Queue")
        icon.name: "media-playlist-play"
        onTriggered:
        {
            queue(model.get(index))
        }
    }

    MenuSeparator{}

    MenuItem
    {
        text: i18n("Select")
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
        text: i18n("Show in folder")
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
        text: i18n("Remove")
        icon.name: "edit-delete"
        Maui.Controls.status: Maui.Controls.Negative
        onTriggered: removeFiles([model.get(index).url])
    }
}
