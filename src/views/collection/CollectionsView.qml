import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

import org.maui.clip as Clip

import ".."

Maui.Page
{
    id: control
    objectName: "CollectionView"

    background: null
    property bool useInternalChrome: true
    Maui.Controls.showCSD: true
    headerMargins: Maui.Style.contentMargins

    focus: true
    focusPolicy: Qt.StrongFocus
    Keys.enabled: true
    Keys.forwardTo: _foldersView

    readonly property bool browsingFolder: _foldersView.depth > 1
    readonly property var currentBrowser: browsingFolder ? _foldersView.currentItem : null

    ListModel
    {
        id: _sourcesModel
    }

    Connections
    {
        target: Clip.Clip

        function onSourcesChanged()
        {
            control.rebuildSourcesModel(_searchField.text)
        }
    }

    Connections
    {
        target: _foldersView

        function onDepthChanged()
        {
            _searchField.text = ""
            control.clearSearch()
        }
    }

    headBar.visible: useInternalChrome

    headBar.leftContent: [
        ToolButton
        {
            visible: control.browsingFolder
            icon.name: "go-previous"
            onClicked: _foldersView.pop()
        },

        ToolSeparator
        {
            visible: control.browsingFolder
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
            id: _searchField
            enabled: control.browsingFolder
                     ? (control.currentBrowser ? control.currentBrowser.list.count > 0 : false)
                     : _sourcesModel.count > 0
            implicitWidth: 250
            placeholderText: control.browsingFolder ? i18n("Search videos") : i18n("Search collections")
            onTextChanged: control.search(text)
            onCleared: control.clearSearch()
            Keys.priority: Keys.AfterItem
            Keys.onReturnPressed: event.accepted = true
        }
    ]

    headBar.rightContent: [
        Maui.ToolButtonMenu
        {
            visible: control.browsingFolder
            icon.name: "view-sort"

            MenuItem
            {
                text: i18n("Title (A-Z)")
                checkable: true
                autoExclusive: true
                checked: settings.sortBy === "label" && settings.sortOrder === Qt.AscendingOrder
                onTriggered:
                {
                    settings.sortBy = "label"
                    settings.sortOrder = Qt.AscendingOrder
                }
            }

            MenuItem
            {
                text: i18n("Title (Z-A)")
                checkable: true
                autoExclusive: true
                checked: settings.sortBy === "label" && settings.sortOrder === Qt.DescendingOrder
                onTriggered:
                {
                    settings.sortBy = "label"
                    settings.sortOrder = Qt.DescendingOrder
                }
            }

            MenuItem
            {
                text: i18n("Date (Newest)")
                checkable: true
                autoExclusive: true
                checked: settings.sortBy === "modified" && settings.sortOrder === Qt.DescendingOrder
                onTriggered:
                {
                    settings.sortBy = "modified"
                    settings.sortOrder = Qt.DescendingOrder
                }
            }

            MenuItem
            {
                text: i18n("Date (Oldest)")
                checkable: true
                autoExclusive: true
                checked: settings.sortBy === "modified" && settings.sortOrder === Qt.AscendingOrder
                onTriggered:
                {
                    settings.sortBy = "modified"
                    settings.sortOrder = Qt.AscendingOrder
                }
            }

            MenuItem
            {
                text: i18n("Size (Smallest)")
                checkable: true
                autoExclusive: true
                checked: settings.sortBy === "size" && settings.sortOrder === Qt.AscendingOrder
                onTriggered:
                {
                    settings.sortBy = "size"
                    settings.sortOrder = Qt.AscendingOrder
                }
            }

            MenuItem
            {
                text: i18n("Size (Largest)")
                checkable: true
                autoExclusive: true
                checked: settings.sortBy === "size" && settings.sortOrder === Qt.DescendingOrder
                onTriggered:
                {
                    settings.sortBy = "size"
                    settings.sortOrder = Qt.DescendingOrder
                }
            }

            MenuItem
            {
                text: i18n("Type (A-Z)")
                checkable: true
                autoExclusive: true
                checked: settings.sortBy === "type" && settings.sortOrder === Qt.AscendingOrder
                onTriggered:
                {
                    settings.sortBy = "type"
                    settings.sortOrder = Qt.AscendingOrder
                }
            }
        },

        ToolSeparator
        {
            visible: control.browsingFolder
            bottomPadding: 10
            topPadding: 10
        },

        Maui.ToolButtonMenu
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
    ]

    Item
    {
        anchors.fill: parent

        StackView
        {
            id: _foldersView
            anchors.fill: parent
            background: null
            initialItem: _sourcesPageComponent
        }
    }

    Component
    {
        id: _sourcesPageComponent

        Maui.Page
        {
            background: null
            flickable: _sourcesGrid.flickable
            headBar.visible: false

            Maui.Theme.inherit: false
            Maui.Theme.colorGroup: Maui.Theme.View

            Component.onCompleted: control.rebuildSourcesModel("")

            Maui.GridBrowser
            {
                id: _sourcesGrid
                anchors.fill: parent
                itemSize: Math.min(260, Math.max(140, Math.floor(availableWidth * 0.3)))
                itemHeight: itemSize + Maui.Style.rowHeight
                currentIndex: -1
                flickable.reuseItems: true

                holder.visible: count === 0
                holder.emoji: "folder-videos"
                holder.title: i18n("No Sources!")
                holder.body: i18n("Add a video source from Settings to browse collections.")

                model: _sourcesModel

                Keys.enabled: true
                Keys.priority: Keys.AfterItem
                Keys.onPressed: (event) =>
                {
                    if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && _sourcesGrid.currentItem) {
                        control.openFolder(_sourcesGrid.currentItem.sourceUrl)
                        event.accepted = true
                    }
                }

                delegate: Item
                {
                    readonly property string sourceUrl: model.url
                    height: GridView.view.cellHeight
                    width: GridView.view.cellWidth

                    Maui.CollageItem
                    {
                        anchors.fill: parent
                        anchors.margins: !root.isWide ? Maui.Style.space.tiny : Maui.Style.space.big

                        imageWidth: 120
                        imageHeight: 120
                        isCurrentItem: parent.GridView.isCurrentItem
                        images: model.preview ? String(model.preview).split(",") : []
                        tooltipText: model.path || model.url

                        template.label1.text: model.label
                        template.label2.text: model.modified ? Qt.formatDateTime(new Date(model.modified), "d MMM yyyy") : ""
                        template.iconSource: model.icon
                        template.iconVisible: true

                        onClicked:
                        {
                            _sourcesGrid.currentIndex = index
                            if (Maui.Handy.singleClick)
                                control.openFolder(model.url)
                        }

                        onDoubleClicked:
                        {
                            _sourcesGrid.currentIndex = index
                            if (!Maui.Handy.singleClick)
                                control.openFolder(model.url)
                        }
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
            id: _folderBrowser
            property string currentFolder: ""
            readonly property var folderInfo: FB.FM.getFileInfo(currentFolder)

            background: null
            allowLassoSelection: false
            showTitle: false
            headBar.visible: false
            list.recursive: false
            listView.cacheBuffer: Math.max(height * 2, Maui.Style.units.gridUnit * 24)
            listView.flickable.reuseItems: true

            holder.title: i18n("No Videos!")
            holder.body: i18n("There are no videos in this collection.")

            gridView.header: Loader
            {
                width: _folderBrowser.width
                sourceComponent: Column
                {
                    spacing: Maui.Style.space.medium

                    Maui.SectionHeader
                    {
                        width: _folderBrowser.width
                        label1.text: _folderBrowser.folderInfo.label || _folderBrowser.currentFolder
                        label2.text: _folderBrowser.folderInfo.path
                                     ? String(_folderBrowser.folderInfo.path).replace(FB.FM.homePath(), "")
                                     : _folderBrowser.currentFolder
                        template.label3.text: i18np("No videos.", "%1 videos", _folderBrowser.list.count)
                        template.label4.text: _folderBrowser.folderInfo.modified
                                             ? Qt.formatDateTime(new Date(_folderBrowser.folderInfo.modified), "d MMM yyyy")
                                             : ""
                        template.iconSource: _folderBrowser.folderInfo.icon

                        template.content: ToolButton
                        {
                            icon.name: "folder-open"
                            onClicked: Qt.openUrlExternally(_folderBrowser.currentFolder)
                        }
                    }
                }
            }

            onItemClicked: play(item)

            Component.onCompleted: syncFolderSource()
            onCurrentFolderChanged: syncFolderSource()

            function syncFolderSource()
            {
                const nextUrls = currentFolder.length ? [currentFolder] : []
                const currentUrls = list.urls

                if (currentUrls.length === nextUrls.length
                        && (currentUrls.length === 0 || currentUrls[0] === nextUrls[0]))
                    return

                list.urls = nextUrls
            }
        }
    }

    function rebuildSourcesModel(filterText)
    {
        const filter = String(filterText || "").trim().toLowerCase()
        const items = Clip.Clip.sourcesModel

        _sourcesModel.clear()

        for (let i = 0; i < items.length; ++i) {
            const item = items[i]
            const label = String(item.label || "").toLowerCase()
            const path = String(item.path || item.url || "").toLowerCase()

            if (!filter || label.includes(filter) || path.includes(filter))
                _sourcesModel.append(item)
        }
    }

    function openFolder(url, filters)
    {
        if (!url || url.length === 0)
            return

        if (_foldersView.depth === 1) {
            _foldersView.push(_folderViewComponent, ({ currentFolder: url }))
        } else if (_foldersView.currentItem.currentFolder !== url) {
            _foldersView.currentItem.currentFolder = url
        }

        _foldersView.forceActiveFocus()
    }

    function search(text)
    {
        if (browsingFolder) {
            if (currentBrowser && currentBrowser.listModel)
                currentBrowser.listModel.filter = text
        } else {
            rebuildSourcesModel(text)
        }
    }

    function clearSearch()
    {
        if (browsingFolder) {
            if (currentBrowser && currentBrowser.listModel)
                currentBrowser.listModel.filter = ""
        } else {
            rebuildSourcesModel("")
        }
    }

    function goBack()
    {
        if (browsingFolder)
            _foldersView.pop()
    }
}
