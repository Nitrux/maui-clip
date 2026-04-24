import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QtMultimedia

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

import org.maui.clip as Clip

import "views"
import "views/player"
import "views/collection"
import "views/tags"
import "views/settings"

Maui.ApplicationWindow
{
    id: root

    title: _playerView.currentVideo.label || i18n("Clip")
    color: "transparent"
    background: null

    property bool selectionMode: false

    readonly property alias player: _playerView
    readonly property var currentRoute: _stackView.currentItem
    readonly property bool viewerActive: _sideBarView.active
    readonly property bool galleryActive: !viewerActive && currentRoute && currentRoute.objectName === "GalleryView"
    readonly property bool collectionsActive: !viewerActive && currentRoute && currentRoute.objectName === "CollectionView"
    readonly property bool tagsActive: !viewerActive && currentRoute && currentRoute.objectName === "TagsView"
    readonly property bool collectionsFolderActive: collectionsActive && currentRoute && currentRoute.browsingFolder
    readonly property bool tagsFilterActive: tagsActive && currentRoute && currentRoute.filteringTag
    readonly property bool tagsGridActive: tagsActive && currentRoute && !currentRoute.filteringTag
    readonly property bool browserSearchVisible: galleryActive || collectionsActive || tagsFilterActive
    readonly property bool browserSortVisible: galleryActive || collectionsFolderActive
    readonly property bool shellBackVisible: viewerActive || collectionsFolderActive || tagsFilterActive
    readonly property string browserSearchPlaceholder: tagsFilterActive
                                                     ? i18n("Search videos")
                                                     : (collectionsActive
                                                        ? (collectionsFolderActive ? i18n("Search videos") : i18n("Search collections"))
                                                        : i18n("Search videos"))

    Maui.WindowBlur
    {
        view: root
        geometry: Qt.rect(0, 0, root.width, root.height)
        windowRadius: Maui.Style.radiusV
        enabled: true
    }

    Rectangle
    {
        anchors.fill: parent
        color: Maui.Theme.backgroundColor
        opacity: 0.76
        radius: Maui.Style.radiusV
        border.color: Qt.rgba(1, 1, 1, 0)
        border.width: 1
    }

    Settings
    {
        id: settings
        property int volumeStep: 5
        property string colorScheme: "Breeze"
        property string sortBy: "modified"
        property int sortOrder: Qt.DescendingOrder
        property bool hardwareDecoding: true
        property string preferredLanguage: "eng"
        property string subtitlesPath
        property font font
        property bool playerTagBar: true
    }

    Loader
    {
        anchors.fill: parent
        asynchronous: true
        sourceComponent: DropArea
        {
            onDropped: (drop) =>
            {
                if (drop.urls)
                    Clip.Clip.openVideos(drop.urls)
            }
        }
    }

    Component
    {
        id: removeDialogComponent

        FB.FileListingDialog
        {
            title: i18n("Delete files?")
            message: i18n("Are sure you want to delete %1 files", urls.length)
            template.iconSource: "emblem-warning"
            onClosed: destroy()

            actions: [
                Action
                {
                    text: i18n("Delete")
                    Maui.Controls.status: Maui.Controls.Negative
                    onTriggered:
                    {
                        for (var url of urls)
                            FB.FM.removeFile(url)

                        close()
                    }
                },

                Action
                {
                    text: i18n("Cancel")
                    onTriggered: close()
                }
            ]
        }
    }

    Component
    {
        id: _settingsDialogComponent
        SettingsDialog
        {
            onClosed: destroy()
        }
    }

    Component
    {
        id: _openUrlDialogComponent
        Maui.InputDialog
        {
            title: i18n("Open URL")
            textEntry.placeholderText: "URL"
            message: i18n("Enter any remote location, like YouTube video URLs, or from other services supported by MPV.")
            onAccepted: root.openUrl(textEntry.text)
            onClosed: destroy()
        }
    }

    property QtObject tagsDialog: null

    Component
    {
        id: tagsDialogComponent
        FB.TagsDialog
        {
            onTagsReady: composerList.updateToUrls(tags)
            composerList.strict: false
        }
    }

    Component
    {
        id: fmDialogComponent
        FB.FileDialog
        {
            browser.settings.filterType: FB.FMList.VIDEO
            onClosed: destroy()
        }
    }

    Playlist
    {
        id: _playlist
        visible: false
        width: 0
        height: 0
    }

    Maui.Page
    {
        id: _shellPage
        anchors.fill: parent
        background: null
        autoHideHeader: viewerActive && _playerView.playbackState === MediaPlayer.PlayingState
        altHeader: viewerActive && Maui.Handy.isMobile
        headerMargins: Maui.Style.contentMargins
        floatingHeader: viewerActive
        headBar.visible: !viewerActive || !_playerHolderLoader.active

        Maui.Controls.showCSD: true

        headBar.leftContent: [
            ToolButton
            {
                visible: shellBackVisible
                icon.name: "go-previous"
                onClicked: handleToolbarBack()
            },

            ToolSeparator
            {
                visible: shellBackVisible
                bottomPadding: 10
                topPadding: 10
            },

            ToolButton
            {
                icon.name: "folder-videos"
                onClicked: showGallery()
            },

            ToolButton
            {
                icon.name: "folder"
                onClicked: showCollections()
            },

            ToolButton
            {
                icon.name: "tag"
                onClicked: showTags()
            },

            ToolSeparator
            {
                visible: browserSearchVisible || tagsGridActive
                bottomPadding: 10
                topPadding: 10
            },

            Maui.SearchField
            {
                id: _toolbarSearchField
                visible: browserSearchVisible
                enabled: visible
                implicitWidth: 250
                placeholderText: browserSearchPlaceholder
                onTextChanged:
                {
                    if (browserSearchVisible && currentRoute && currentRoute.search)
                        currentRoute.search(text)
                }
                onCleared:
                {
                    if (browserSearchVisible && currentRoute && currentRoute.clearSearch)
                        currentRoute.clearSearch()
                }
                Keys.priority: Keys.AfterItem
                Keys.onReturnPressed: event.accepted = true
            },

            Label
            {
                visible: tagsGridActive
                text: i18n("Sort")
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            },

            ComboBox
            {
                id: _tagsSortComboBox
                visible: tagsGridActive
                implicitWidth: 180
                model: [
                    i18n("Name (A-Z)"),
                    i18n("Name (Z-A)"),
                    i18n("Date (Newest)"),
                    i18n("Date (Oldest)")
                ]

                Binding on currentIndex
                {
                    when: tagsGridActive && currentRoute && currentRoute.currentSortIndex
                    value: currentRoute.currentSortIndex()
                    restoreMode: Binding.RestoreBinding
                }

                onActivated: (index) =>
                {
                    if (tagsGridActive && currentRoute && currentRoute.applySort)
                        currentRoute.applySort(index)
                }
            }
        ]

        headBar.rightContent: [
            Maui.ToolButtonMenu
            {
                visible: browserSortVisible
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
                visible: browserSortVisible
                bottomPadding: 10
                topPadding: 10
            },

            Maui.ToolButtonMenu
            {
                visible: viewerActive
                icon.name: "configure"

                MenuItem
                {
                    text: root.visibility === Window.FullScreen ? i18n("Exit Full Screen") : i18n("Full Screen")
                    icon.name: root.visibility === Window.FullScreen ? "view-restore" : "view-fullscreen"
                    onTriggered: root.toggleFullScreen()
                }

                MenuSeparator {}

                MenuItem
                {
                    text: i18n("Fit to Screen")
                    checkable: true
                    autoExclusive: true
                    checked: player.fillMode === VideoOutput.PreserveAspectFit
                    onTriggered: player.fillMode = VideoOutput.PreserveAspectFit
                }

                MenuItem
                {
                    text: i18n("Crop to Screen")
                    checkable: true
                    autoExclusive: true
                    checked: player.fillMode === VideoOutput.PreserveAspectCrop
                    onTriggered: player.fillMode = VideoOutput.PreserveAspectCrop
                }

                MenuItem
                {
                    text: i18n("Stretch to Screen")
                    checkable: true
                    autoExclusive: true
                    checked: player.fillMode === VideoOutput.Stretch
                    onTriggered: player.fillMode = VideoOutput.Stretch
                }
            },

            Maui.ToolButtonMenu
            {
                visible: !viewerActive
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

        StackView
        {
            id: _stackView
            anchors.fill: parent
            background: null
            initialItem: _galleryViewComponent
            Maui.Theme.colorSet: Maui.Theme.View

            onCurrentItemChanged: resetToolbarSearch()

            Component
            {
                id: _galleryViewComponent
                CollectionView
                {
                    useInternalChrome: false
                }
            }

            Component
            {
                id: _collectionsViewComponent
                CollectionsView
                {
                    useInternalChrome: false
                }
            }

            Component
            {
                id: _tagsViewComponent
                TagsView
                {
                    useInternalChrome: false
                }
            }

            Maui.SideBarView
            {
                id: _sideBarView
                focus: true
                visible: StackView.status !== StackView.Inactive
                readonly property bool active: StackView.status === StackView.Active

                sideBar.enabled: false
                background: null

                Maui.Page
                {
                    id: _playerPage
                    anchors.fill: parent
                    background: null
                    headBar.visible: false

                    Maui.Controls.showCSD: true

                    Keys.enabled: !Maui.Handy.isMobile
                    Keys.onSpacePressed: player.playbackState === MediaPlayer.PlayingState ? player.pause() : player.play()
                    Keys.onLeftPressed: player.seek(player.position - 500)
                    Keys.onRightPressed: player.seek(player.position + 500)

                    PlayerView
                    {
                        id: _playerView
                        anchors.fill: parent
                    }

                    Loader
                    {
                        anchors.fill: parent
                        asynchronous: true

                        sourceComponent: RowLayout
                        {
                            MouseArea
                            {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                onDoubleClicked: player.seek(player.position - 5)
                            }

                            MouseArea
                            {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                onClicked: player.playbackState === MediaPlayer.PlayingState ? player.pause() : player.play()
                                onDoubleClicked: root.toggleFullScreen()
                            }

                            MouseArea
                            {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                onDoubleClicked: player.seek(player.position + 5)
                            }
                        }
                    }

                    Loader
                    {
                        id: _playerHolderLoader
                        anchors.fill: parent
                        active: _playerView.isStopped && _playerView.error !== MediaPlayer.NoError
                        asynchronous: true
                        visible: active
                        sourceComponent: Maui.Holder
                        {
                            emoji: "media-playback-start"
                            title: i18n("Nothing Here!")
                            body: _playerView.error !== MediaPlayer.NoError ? _playerView.errorString : i18n("Open a new video from your collection or file system.")
                            actions: [
                                Action
                                {
                                    text: i18n("Open")
                                    onTriggered: root.openFileDialog()
                                },

                                Action
                                {
                                    text: i18n("Collection")
                                    onTriggered: showGallery()
                                }
                            ]
                        }
                    }

                    floatingFooter: true
                    footerMargins: Maui.Style.contentMargins

                    footBar.middleContent: Slider
                    {
                        id: _slider
                        Layout.fillWidth: true
                        padding: 0
                        orientation: Qt.Horizontal
                        from: 0
                        to: player.duration
                        value: player.position
                        Layout.preferredHeight: 22
                        onMoved: player.seek(_slider.value)
                        spacing: 0
                        focus: true
                    }

                    footBar.rightContent: [
                        Label
                        {
                            text: Maui.Handy.formatTime(player.duration / 1000) + " / " + Maui.Handy.formatTime(player.position / 1000)
                        }
                    ]

                    footBar.leftContent: Maui.ToolActions
                    {
                        expanded: true
                        checkable: false
                        autoExclusive: false

                        Action
                        {
                            icon.name: "media-skip-backward"
                            onTriggered: playPrevious()
                        }

                        Action
                        {
                            icon.name: player.isPlaying ? "media-playback-pause" : "media-playback-start"
                            onTriggered: player.isPaused ? player.play() : player.pause()
                        }

                        Action
                        {
                            icon.name: "media-skip-forward"
                            onTriggered: playNext()
                        }
                    }
                }
            }
        }
    }

    Connections
    {
        target: currentRoute
        ignoreUnknownSignals: true

        function onBrowsingFolderChanged()
        {
            resetToolbarSearch()
        }

        function onFilteringTagChanged()
        {
            resetToolbarSearch()
        }
    }

    Connections
    {
        target: Clip.Clip

        function onOpenUrls(urls)
        {
            for (var url of urls)
                _playlist.list.appendUrl(url)

            playAt(_playlist.count - urls.length)
        }
    }

    function resetToolbarSearch()
    {
        _toolbarSearchField.text = ""
    }

    function handleToolbarBack()
    {
        if (viewerActive) {
            toggleViewer()
            return
        }

        if ((collectionsFolderActive || tagsFilterActive) && currentRoute && currentRoute.goBack) {
            resetToolbarSearch()
            currentRoute.goBack()
            currentRoute.forceActiveFocus()
        }
    }

    function showGallery()
    {
        resetToolbarSearch()
        _stackView.pop(null)
        _stackView.currentItem.forceActiveFocus()
    }

    function showCollections()
    {
        resetToolbarSearch()

        if (_stackView.currentItem.objectName === "CollectionView")
            return

        if (_sideBarView.active)
            _stackView.pop()

        if (_stackView.currentItem.objectName !== "CollectionView")
            _stackView.push(_collectionsViewComponent)

        _stackView.currentItem.forceActiveFocus()
    }

    function showTags()
    {
        resetToolbarSearch()

        if (_stackView.currentItem.objectName === "TagsView")
            return

        if (_sideBarView.active)
            _stackView.pop()

        if (_stackView.currentItem.objectName !== "TagsView")
            _stackView.push(_tagsViewComponent)

        _stackView.currentItem.forceActiveFocus()
    }

    function openFolder(url, filters)
    {
        showCollections()
        _stackView.currentItem.openFolder(url, filters)
    }

    function toggleViewer()
    {
        if (_sideBarView.active)
        {
            _stackView.pop()
        } else {
            resetToolbarSearch()
            _stackView.push(_sideBarView)
        }

        _stackView.currentItem.forceActiveFocus()
    }

    function toggleFullScreen()
    {
        if (root.visibility === Window.FullScreen)
            root.showNormal()
        else
            root.showFullScreen()
    }

    function playNext()
    {
        if (_playlist.list.count > 0)
        {
            const next = _playerView.currentVideoIndex + 1 >= _playlist.list.count ? 0 : _playerView.currentVideoIndex + 1
            playAt(next)
        }
    }

    function playPrevious()
    {
        if (_playlist.list.count > 0)
        {
            const previous = _playerView.currentVideoIndex - 1 >= 0 ? _playerView.currentVideoIndex - 1 : _playlist.list.count - 1
            playAt(previous)
        }
    }

    function play(item)
    {
        queue(item)
        playAt(_playlist.list.count - 1)
    }

    function playAt(index)
    {
        if ((index < _playlist.list.count) && (index > -1))
        {
            _playerView.currentVideoIndex = index
            _playerView.currentVideo = _playlist.model.get(index)

            if (!_sideBarView.active)
                toggleViewer()

            _playerView.play()
        }
    }

    function playItems(items)
    {
        _playlist.list.clear()

        for (var item of items)
            queue(item)

        playAt(0)
    }

    function queueItems(items)
    {
        for (var item of items)
            queue(item)
    }

    function queue(item)
    {
        _playlist.append(item)
    }

    function openFileDialog()
    {
        const props = ({
            'callback': function(paths)
            {
                Clip.Clip.openVideos(paths)
            }
        })

        const dialog = fmDialogComponent.createObject(root, props)
        dialog.open()
    }

    function openSettingsDialog()
    {
        const dialog = _settingsDialogComponent.createObject(root)
        dialog.open()
    }

    function openUrl(url)
    {
        if (!url || url.length === 0)
            return

        _playerView.currentVideoIndex = -1
        _playerView.currentVideo = ({ label: url, url: url, preview: "" })

        if (!_sideBarView.active)
            toggleViewer()

        _playerView.play()
    }

    function tagFiles(urls)
    {
        if (!tagsDialog)
            tagsDialog = tagsDialogComponent.createObject(root)

        tagsDialog.composerList.urls = urls
        tagsDialog.open()
    }

    function saveFiles(urls)
    {
        const props = ({
            'browser.settings.onlyDirs': true,
            'singleSelection': true,
            'callback': function(paths)
            {
                FB.FM.copy(urls, paths[0])
            }
        })

        const dialog = fmDialogComponent.createObject(root, props)
        dialog.open()
    }

    function removeFiles(urls)
    {
        const dialog = removeDialogComponent.createObject(root, ({ 'urls': urls }))
        dialog.open()
    }
}
