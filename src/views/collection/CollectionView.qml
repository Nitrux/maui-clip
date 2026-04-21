import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui

import ".."

BrowserLayout
{
    id: control
    objectName: "GalleryView"

    background: null
    Maui.Controls.showCSD: true
    headerMargins: Maui.Style.contentMargins

    holder.emoji: "folder-videos"
    holder.title: i18n("No Videos!")
    holder.body: i18n("Nothing here. You can add new sources or open a video.")
    holder.actions: [
        Action
        {
            text: i18n("Open File")
            onTriggered: openFileDialog()
        },

        Action
        {
            text: i18n("Add Source")
            onTriggered: openSettingsDialog()
        }
    ]

    onItemClicked: play(item)
}
