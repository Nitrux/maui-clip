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

    Maui.Style.styleType: _sideBarView.active ? Maui.Style.Dark : undefined

    title: _playerView.currentVideo.label || i18n("Clip")
    color: "transparent"
    background: null

    property bool selectionMode: false

    readonly property alias player: _playerView

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

    StackView
    {
        id: _stackView
        anchors.fill: parent
        initialItem: initModule === "viewer" ? _sideBarView : _galleryViewComponent
        Maui.Theme.colorSet: Maui.Theme.View

        Component
        {
            id: _galleryViewComponent
            CollectionView {}
        }

        Component
        {
            id: _collectionsViewComponent
            CollectionsView {}
        }

        Component
        {
            id: _tagsViewComponent
            TagsView {}
        }

        Maui.SideBarView
        {
            id: _sideBarView
            focus: true
            readonly property bool active: StackView.status === StackView.Active

            sideBar.enabled: false
            background: null

            Maui.Page
            {
                id: _playerPage
                anchors.fill: parent
                background: null
                autoHideHeader: _playerView.playbackState === MediaPlayer.PlayingState
                altHeader: Maui.Handy.isMobile
                headerMargins: Maui.Style.contentMargins
                floatingHeader: true
                headBar.visible: !_playerHolderLoader.active

                Maui.Controls.showCSD: true

                onGoBackTriggered: toggleViewer()

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

                headBar.leftContent: [
                    ToolButton
                    {
                        icon.name: "go-previous"
                        onClicked: toggleViewer()
                    },

                    ToolSeparator
                    {
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
                    }
                ]

                headBar.rightContent: [
                    FB.FavButton
                    {
                        url: _playerView.source
                    },

                    ToolSeparator
                    {
                        bottomPadding: 10
                        topPadding: 10
                    },

                    Maui.ToolButtonMenu
                    {
                        icon.name: "overflow-menu"

                        MenuItem
                        {
                            text: i18n("Open File")
                            icon.name: "folder-open"
                            onTriggered: root.openFileDialog()
                        }

                        MenuItem
                        {
                            visible: Clip.Clip.mpvAvailable
                            text: i18n("Open URL")
                            icon.name: "filename-space-amarok"
                            onTriggered: _openUrlDialog.open()
                        }

                        MenuItem
                        {
                            text: root.visibility === Window.FullScreen ? i18n("Exit Full Screen") : i18n("Full Screen")
                            icon.name: root.visibility === Window.FullScreen ? "view-restore" : "view-fullscreen"
                            onTriggered: root.visibility === Window.FullScreen ? root.showNormal() : root.showFullScreen()
                        }

                        MenuItem
                        {
                            visible: Clip.Clip.mpvAvailable
                            text: i18n("Subtitles")
                            onTriggered: _subtitlesDialog.open()
                        }

                        MenuItem
                        {
                            visible: Clip.Clip.mpvAvailable
                            text: i18n("Audio")
                            onTriggered: _audioTracksDialog.open()
                        }

                        MenuSeparator {}

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
                    },

                    ToolButton
                    {
                        icon.name: "zoom-fit-width"
                        checkable: true
                        checked: player.fillMode == VideoOutput.PreserveAspectFit
                        onClicked:
                        {
                            if (!checked)
                                player.fillMode = VideoOutput.PreserveAspectCrop
                            else
                                player.fillMode = VideoOutput.PreserveAspectFit
                        }
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

    function ensureMainView()
    {
        if (_sideBarView.active)
        {
            if (_stackView.depth === 1)
                _stackView.replace(_sideBarView, _galleryViewComponent)
            else
                _stackView.pop()
        }

        if (_stackView.currentItem.objectName !== "GalleryView" && _stackView.depth > 1)
            _stackView.pop(null)
    }

    function showGallery()
    {
        ensureMainView()
        _stackView.currentItem.forceActiveFocus()
    }

    function showCollections()
    {
        ensureMainView()

        if (_stackView.currentItem.objectName !== "CollectionView")
            _stackView.push(_collectionsViewComponent)

        _stackView.currentItem.forceActiveFocus()
    }

    function showTags()
    {
        ensureMainView()

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
            if (_stackView.depth === 1)
                _stackView.replace(_sideBarView, _galleryViewComponent)
            else
                _stackView.pop()
        } else {
            _stackView.push(_sideBarView)
        }

        _stackView.currentItem.forceActiveFocus()
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
