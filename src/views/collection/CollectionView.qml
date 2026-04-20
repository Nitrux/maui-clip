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
    headBar.middleContent: []

    holder.emoji: "qrc:/img/assets/view-media-video.svg"
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

    headBar.leftContent: [
        ToolButton
        {
            icon.name: "folder-videos"
            onClicked: ApplicationWindow.window.showGallery()
        },

        ToolButton
        {
            icon.name: "folder"
            onClicked: ApplicationWindow.window.showCollections()
        },

        ToolButton
        {
            icon.name: "tag"
            onClicked: ApplicationWindow.window.showTags()
        },

        ToolSeparator
        {
            bottomPadding: 10
            topPadding: 10
        },

        Maui.SearchField
        {
            implicitWidth: 250
            placeholderText: i18np("Search %1 video", "Search %1 videos", control.list.count)
            onTextChanged: control.listModel.filter = text
            onCleared: control.listModel.filter = ""
            Keys.priority: Keys.AfterItem
            Keys.onReturnPressed: event.accepted = true
        }
    ]



    onItemClicked: play(item)
}
