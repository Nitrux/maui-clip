import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui

import org.maui.clip as Clip
import QtMultimedia

Maui.AltBrowser
{
    id: control

    background: null
    property string searchPlaceholder: i18n("Search videos")
    property bool showSortMenu: true

    property alias list: _collectionList
    property alias urls: _collectionList.urls
    property alias listModel: _collectionModel
    property alias searchField: _searchField
    property var selectionBar: null

    signal itemClicked(var item)
    signal itemRightClicked(var item)

    readonly property var sortOptions: [
        { text: i18n("Title (A-Z)"), sort: "label", order: Qt.AscendingOrder },
        { text: i18n("Title (Z-A)"), sort: "label", order: Qt.DescendingOrder },
        { text: i18n("Date (Newest)"), sort: "modified", order: Qt.DescendingOrder },
        { text: i18n("Date (Oldest)"), sort: "modified", order: Qt.AscendingOrder },
        { text: i18n("Size (Smallest)"), sort: "size", order: Qt.AscendingOrder },
        { text: i18n("Size (Largest)"), sort: "size", order: Qt.DescendingOrder },
        { text: i18n("Type (A-Z)"), sort: "type", order: Qt.AscendingOrder }
    ]

    headBar.forceCenterMiddleContent: false
    gridView.itemSize: 180

    enableLassoSelection: true

    holder.visible: _collectionList.count === 0
    holder.emojiSize: Maui.Style.iconSizes.huge

    viewType: control.width < Maui.Style.units.gridUnit * 30 ? Maui.AltBrowser.ViewType.List : Maui.AltBrowser.ViewType.Grid

    Connections
    {
        target: control.currentView
        ignoreUnknownSignals: true

        function onItemsSelected(indexes)
        {
            if (!selectionBar)
                return

            for (var i in indexes)
                selectionBar.insert(_collectionModel.get(indexes[i]))
        }

        function onKeyPress(event)
        {
            const index = control.currentIndex

            if ((event.key == Qt.Key_Left || event.key == Qt.Key_Right || event.key == Qt.Key_Down || event.key == Qt.Key_Up) && (event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier))
                control.currentView.itemsSelected([index])
        }
    }

    ItemMenu
    {
        id: _menu
        index: control.currentIndex
        model: control.model
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

        Maui.SearchField
        {
            id: _searchField
            enabled: _collectionList.count > 0
            implicitWidth: 250
            placeholderText: control.searchPlaceholder
            onTextChanged: _collectionModel.filter = text
            onCleared: _collectionModel.filter = ""
            Keys.priority: Keys.AfterItem
            Keys.onReturnPressed: event.accepted = true
        }
    ]

    headBar.rightContent: [
        Maui.ToolButtonMenu
        {
            visible: control.showSortMenu
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
            bottomPadding: 10
            topPadding: 10
            visible: control.showSortMenu
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

    model: Maui.BaseModel
    {
        id: _collectionModel
        sortOrder: settings.sortOrder
        sort: settings.sortBy
        recursiveFilteringEnabled: true
        sortCaseSensitivity: Qt.CaseInsensitive
        filterCaseSensitivity: Qt.CaseInsensitive
        list: Clip.Videos
        {
            id: _collectionList
            urls: ["collection:///"]
        }
    }

    listDelegate: ListDelegate
    {
        id: _listDelegate
        width: ListView.view.width

        onToggled: (state) =>
        {
            control.currentIndex = index
            control.currentView.itemsSelected([index])
        }

        onClicked: (mouse) =>
        {
            control.currentIndex = index
            if (selectionMode || (mouse.button == Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier))) {
                control.currentView.itemsSelected([index])
            } else if (Maui.Handy.singleClick) {
                control.itemClicked(listModel.get(index))
            }
        }

        onDoubleClicked:
        {
            control.currentIndex = index
            if (!Maui.Handy.singleClick && !selectionMode)
                control.itemClicked(listModel.get(index))
        }

        onPressAndHold:
        {
            if (!Maui.Handy.isTouch)
                return

            control.currentIndex = index
            control.itemRightClicked(listModel.get(index))
            _menu.show()
        }

        onRightClicked:
        {
            control.currentIndex = index
            control.itemRightClicked(listModel.get(index))
            _menu.show()
        }

        Connections
        {
            target: selectionBar

            function onUriRemoved(uri)
            {
                if (uri === model.url)
                    _listDelegate.checked = false
            }

            function onUriAdded(uri)
            {
                if (uri === model.url)
                    _listDelegate.checked = true
            }

            function onCleared(uri)
            {
                _listDelegate.checked = false
            }
        }
    }

    gridDelegate: Item
    {
        readonly property bool isCurrentItem: GridView.isCurrentItem
        height: GridView.view.cellHeight
        width: GridView.view.cellWidth

        property bool preview: false

        Timer
        {
            id: _timer
            interval: 1500
            onTriggered: parent.preview = true
        }

        Maui.GridBrowserDelegate
        {
            id: delegate

            onHoveredChanged:
            {
                if (hovered) {
                    _timer.start()
                } else {
                    _timer.stop()
                    preview = false
                }
            }

            iconSizeHint: Maui.Style.iconSizes.big
            label1.text: model.label

            anchors.centerIn: parent
            height: control.gridView.cellHeight - 15
            width: control.gridView.itemSize - 20
            padding: Maui.Style.space.tiny
            isCurrentItem: parent.isCurrentItem || checked
            tooltipText: model.url
            checkable: root.selectionMode || checked
            checked: selectionBar ? selectionBar.contains(model.url) : false
            draggable: true

            Drag.keys: ["text/uri-list"]
            Drag.mimeData: Drag.active ? {
                "text/uri-list": control.filterSelectedItems(model.url)
            } : {}

            template.iconComponent: Loader
            {
                asynchronous: true
                sourceComponent: preview && !Maui.Handy.isMobile ? videoComponent : imgComponent

                Component
                {
                    id: videoComponent
                    Video
                    {
                        autoPlay: true
                        source: model.url
                        muted: true
                        fillMode: VideoOutput.PreserveAspectFit
                        playbackRate: 5.0
                        loops: 3
                    }
                }

                Component
                {
                    id: imgComponent
                    Maui.IconItem
                    {
                        imageSource: model.preview
                        iconSource: model.icon
                        fillMode: Image.PreserveAspectFit
                        image.cache: true
                    }
                }
            }

            onClicked: (mouse) =>
            {
                control.currentIndex = index
                if (selectionMode || (mouse.button == Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier))) {
                    control.currentView.itemsSelected([index])
                } else if (Maui.Handy.singleClick) {
                    control.itemClicked(listModel.get(index))
                }
            }

            onDoubleClicked:
            {
                control.currentIndex = index
                if (!Maui.Handy.singleClick && !selectionMode)
                    control.itemClicked(listModel.get(index))
            }

            onPressAndHold:
            {
                if (!Maui.Handy.isTouch)
                    return

                control.currentIndex = index
                control.itemRightClicked(listModel.get(index))
                _menu.show()
            }

            onRightClicked:
            {
                control.currentIndex = index
                control.itemRightClicked(listModel.get(index))
                _menu.show()
            }

            onToggled:
            {
                control.currentIndex = index
                control.currentView.itemsSelected([index])
            }

            onContentDropped:
            {
            }

            Connections
            {
                target: selectionBar

                function onUriRemoved(uri)
                {
                    if (uri === model.url)
                        delegate.checked = false
                }

                function onUriAdded(uri)
                {
                    if (uri === model.url)
                        delegate.checked = true
                }

                function onCleared(uri)
                {
                    delegate.checked = false
                }
            }
        }
    }

    function filterSelectedItems(url)
    {
        if (selectionBar && selectionBar.count > 0 && selectionBar.contains(url))
            return selectionBar.uris.join("\n")

        return url
    }
}
