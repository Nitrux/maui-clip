import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

import org.maui.clip as Clip

import ".."

StackView
{
    id: control
    objectName: "CollectionView"
    background: null

    property string currentSourceUrl: ""
    property string currentSourceLabel: ""

    initialItem: _sourcesViewComponent

    Component
    {
        id: _sourcesViewComponent

        Maui.Page
        {
            background: null
            Maui.Controls.showCSD: true
            headerMargins: Maui.Style.contentMargins

            headBar.leftContent: [
                ToolButton
                {
                    icon.name: "view-preview"
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
                }
            ]

            headBar.middleContent: Label
            {
                text: i18n("Collections")
                font.weight: Font.DemiBold
            }

            headBar.rightContent: Maui.ToolButtonMenu
            {
                icon.name: "overflow-menu"

                MenuItem
                {
                    text: i18n("Settings")
                    icon.name: "settings-configure"
                    onTriggered: openSettingsDialog()
                }

                MenuItem
                {
                    text: i18n("About")
                    icon.name: "documentinfo"
                    onTriggered: Maui.App.aboutDialog()
                }
            }

            Loader
            {
                anchors.fill: parent
                asynchronous: true
                sourceComponent: Maui.ListBrowser
                {
                    id: _sourcesBrowser
                    anchors.fill: parent
                    model: Clip.Clip.sourcesModel

                    holder.visible: count === 0
                    holder.emoji: "folder-videos"
                    holder.title: i18n("No Sources!")
                    holder.body: i18n("Add a video source from Settings to browse collections.")

                    delegate: Maui.ListDelegate
                    {
                        width: ListView.view.width
                        template.iconSource: modelData.icon
                        template.iconSizeHint: Maui.Style.iconSizes.small
                        template.label1.text: modelData.label
                        template.label2.text: modelData.path || modelData.url

                        onClicked: control.openFolder(modelData.url)
                    }
                }
            }
        }
    }

    Component
    {
        id: _folderViewComponent

        BrowserLayout
        {
            property string folderUrl: ""
            property string folderLabel: ""

            background: null
            title: folderLabel
            list.urls: folderUrl.length ? [folderUrl] : []
            list.recursive: false
            Maui.Controls.showCSD: true
            headerMargins: Maui.Style.contentMargins

            holder.title: i18n("No Videos!")
            holder.body: i18n("There are no videos in this collection.")

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
                    icon.name: "view-preview"
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
                }
            ]

            onItemClicked: play(item)
        }
    }

    function openFolder(url, filters)
    {
        currentSourceUrl = url
        currentSourceLabel = FB.FM.getFileInfo(url).label || url

        if (control.depth > 1)
            control.pop()

        control.push(_folderViewComponent, {
            folderUrl: currentSourceUrl,
            folderLabel: currentSourceLabel
        })
    }
}
