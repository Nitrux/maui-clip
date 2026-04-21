import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui

import ".."

StackView
{
    id: control
    objectName: "TagsView"
    background: null

    property string currentTag: ""
    property Flickable flickable: currentItem.flickable

    initialItem: TagsGrid
    {
        id: _tagsGrid
    }

    Component
    {
        id: _filterViewComponent

        BrowserLayout
        {
            id: _tagBrowser
            showTitle: false
            title: control.currentTag
            background: null
            list.urls: ["tags:///" + currentTag]
            list.recursive: false
            holder.title: i18n("No Videos!")
            holder.body: i18n("There are no videos associated with this tag.")
            headBar.visible: true
            headBar.leftContent: [
                ToolButton
                {
                    icon.name: "go-previous"
                    onClicked: control.pop()
                },

                ToolSeparator
                {
                    bottomPadding: 10
                    topPadding: 10
                },

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
                    enabled: _tagBrowser.list.count > 0
                    implicitWidth: 250
                    placeholderText: i18n("Search videos")
                    onTextChanged: _tagBrowser.listModel.filter = text
                    onCleared: _tagBrowser.listModel.filter = ""
                    Keys.priority: Keys.AfterItem
                    Keys.onReturnPressed: event.accepted = true
                }
            ]

            onItemClicked: play(item)
        }
    }

    function populateGrid(myTag)
    {
        currentTag = myTag

        if (control.depth > 1)
            control.pop()

        control.push(_filterViewComponent)
    }
}
