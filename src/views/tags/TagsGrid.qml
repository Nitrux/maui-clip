import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.maui.clip as Clip

Maui.AltBrowser
{
    id: control

    background: null
    property bool useInternalChrome: true
    Maui.Controls.showCSD: true
    headerMargins: Maui.Style.contentMargins
    gridView.itemSize: Math.min(200, Math.max(100, Math.floor(width * 0.3)))
    gridView.itemHeight: gridView.itemSize + Maui.Style.rowHeight

    headBar.visible: useInternalChrome
    headBar.forceCenterMiddleContent: root.isWide
    holder.visible: _tagsList.count === 0
    holder.emojiSize: Maui.Style.iconSizes.huge
    holder.emoji: "tag"
    holder.title: i18n("No Tags!")
    holder.body: i18n("Add a new tag to start organizing your video collection.")

    Binding on viewType
    {
        value: control.width < Maui.Style.units.gridUnit * 30 ? Maui.AltBrowser.ViewType.List : Maui.AltBrowser.ViewType.Grid
        restoreMode: Binding.RestoreBinding
    }

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

        Label
        {
            text: i18n("Sort")
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
        },

        ComboBox
        {
            id: _sortComboBox
            implicitWidth: 180
            currentIndex: 0

            model: [
                i18n("Name (A-Z)"),
                i18n("Name (Z-A)"),
                i18n("Date (Newest)"),
                i18n("Date (Oldest)")
            ]

            readonly property var sortOptions: [
                { sort: "tag", order: Qt.AscendingOrder },
                { sort: "tag", order: Qt.DescendingOrder },
                { sort: "modified", order: Qt.DescendingOrder },
                { sort: "modified", order: Qt.AscendingOrder }
            ]

            onActivated: (index) =>
            {
                _collectionModel.sort = sortOptions[index].sort
                _collectionModel.sortOrder = sortOptions[index].order
            }
        }
    ]

    headBar.rightContent: [
        Maui.ToolButtonMenu
        {
            icon.name: "overflow-menu"

            MenuItem
            {
                text: i18n("Settings")
                icon.name: "settings-configure"
                onTriggered: ApplicationWindow.window.openSettingsDialog()
            }

            MenuItem
            {
                text: i18n("About")
                icon.name: "documentinfo"
                onTriggered: Maui.App.aboutDialog()
            }
        }
    ]

    model: Maui.BaseModel
    {
        id: _collectionModel
        sortOrder: Qt.AscendingOrder
        sort: "tag"
        recursiveFilteringEnabled: true
        sortCaseSensitivity: Qt.CaseInsensitive
        filterCaseSensitivity: Qt.CaseInsensitive
        list: Clip.Tags
        {
            id: _tagsList
        }
    }

    listDelegate: Maui.ListBrowserDelegate
    {
        width: ListView.view.width
        label1.text: model.tag
        iconSource: model.icon
        iconSizeHint: Maui.Style.iconSize

        onClicked:
        {
            control.currentIndex = index
            if (Maui.Handy.singleClick)
                populateGrid(model.tag)
        }

        onDoubleClicked:
        {
            control.currentIndex = index
            if (!Maui.Handy.singleClick)
                populateGrid(model.tag)
        }
    }

    gridDelegate: Item
    {
        height: GridView.view.cellHeight
        width: GridView.view.cellWidth

        Maui.CollageItem
        {
            width: control.gridView.itemSize - Maui.Style.space.medium
            height: control.gridView.itemHeight - Maui.Style.space.medium

            isCurrentItem: parent.GridView.isCurrentItem
            images: model.preview.split(",")
            cb: function(url) { return "image://thumbnailer/" + url }

            template.label1.text: model.tag
            template.iconSource: model.icon
            template.iconVisible: true

            onClicked:
            {
                control.currentIndex = index
                if (Maui.Handy.singleClick)
                    populateGrid(model.tag)
            }

            onDoubleClicked:
            {
                control.currentIndex = index
                if (!Maui.Handy.singleClick)
                    populateGrid(model.tag)
            }
        }
    }

    readonly property var sortOptions: _sortComboBox.sortOptions

    function currentSortIndex()
    {
        for (let i = 0; i < sortOptions.length; ++i) {
            const option = sortOptions[i]

            if (_collectionModel.sort === option.sort && _collectionModel.sortOrder === option.order)
                return i
        }

        return 0
    }

    function applySort(index)
    {
        if (index < 0 || index >= sortOptions.length)
            return

        _collectionModel.sort = sortOptions[index].sort
        _collectionModel.sortOrder = sortOptions[index].order
    }

    function search(text)
    {
        _collectionModel.filter = text
    }

    function clearSearch()
    {
        _collectionModel.filter = ""
    }
}
