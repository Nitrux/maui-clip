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
    property int lastAudibleVolume: 100
    property bool suppressToolbarSearchCallbacks: false

    readonly property alias player: _playerView
    readonly property alias selectionBar: _selectionBar
    readonly property var currentRoute: _libraryTabs.currentIndex === 0 ? _collectionsView
                                      : (_libraryTabs.currentIndex === 1 ? _tagsView
                                         : _playlist)
    readonly property bool collectionsActive: _libraryTabs.currentIndex === 0
    readonly property bool tagsActive: _libraryTabs.currentIndex === 1
    readonly property bool playlistActive: _libraryTabs.currentIndex === 2
    readonly property bool collectionsFolderActive: !!(collectionsActive && currentRoute && currentRoute.browsingFolder)
    readonly property bool tagsFilterActive: !!(tagsActive && currentRoute && currentRoute.filteringTag)
    readonly property bool tagsGridActive: !!(tagsActive && currentRoute && !currentRoute.filteringTag)
    readonly property bool fullScreenPlaybackChromeAutoHide: settings.hidePlayerChromeInFullScreen
                                                             && root.visibility === Window.FullScreen
                                                             && !!_playerView.currentVideo.url
    readonly property bool fullScreenPlaybackChromeVisible: !fullScreenPlaybackChromeAutoHide
                                                            || _fullScreenTopRevealArea.containsMouse
                                                            || _fullScreenBottomRevealArea.containsMouse
    property real fullScreenPlaybackChromeOpacity: fullScreenPlaybackChromeVisible ? 1 : 0

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

    Behavior on fullScreenPlaybackChromeOpacity
    {
        NumberAnimation
        {
            duration: 180
            easing.type: Easing.InOutQuad
        }
    }

    MouseArea
    {
        id: _fullScreenTopRevealArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(Maui.Style.units.gridUnit * 4, _shellPage.headBar.height + Maui.Style.space.big)
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        enabled: fullScreenPlaybackChromeAutoHide
        visible: enabled
        z: 1200
    }

    MouseArea
    {
        id: _fullScreenBottomRevealArea
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(Maui.Style.units.gridUnit * 4, _playerPage.footBar.height + Maui.Style.space.big)
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        enabled: fullScreenPlaybackChromeAutoHide
        visible: enabled
        z: 1200
    }

    Settings
    {
        id: settings
        property string colorScheme: "Breeze"
        property string sortBy: "modified"
        property int sortOrder: Qt.DescendingOrder
        property bool hardwareDecoding: true
        property bool hidePlayerChromeInFullScreen: false
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

    Shortcut
    {
        sequence: "Ctrl+O"
        context: Qt.WindowShortcut
        onActivated: openFileDialog()
    }

    Shortcut
    {
        sequence: "Ctrl+Shift+O"
        context: Qt.WindowShortcut
        onActivated: openUrlDialog()
    }

    Shortcut
    {
        sequence: "Ctrl+1"
        context: Qt.WindowShortcut
        onActivated: showCollections()
    }

    Shortcut
    {
        sequence: "Ctrl+2"
        context: Qt.WindowShortcut
        onActivated: showTags()
    }

    Shortcut
    {
        sequence: "Ctrl+3"
        context: Qt.WindowShortcut
        onActivated: showQueue()
    }

    Shortcut
    {
        sequence: "F11"
        context: Qt.WindowShortcut
        onActivated: toggleFullScreen()
    }

    Shortcut
    {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: root.visibility === Window.FullScreen
        onActivated: root.showNormal()
    }

    Maui.Page
    {
        id: _shellPage
        anchors.fill: parent
        background: null
        autoHideHeader: false
        altHeader: Maui.Handy.isMobile
        headerMargins: Maui.Style.contentMargins
        floatingHeader: true
        headBar.visible: !fullScreenPlaybackChromeAutoHide || fullScreenPlaybackChromeOpacity > 0.01
        headBar.enabled: fullScreenPlaybackChromeOpacity > 0.01
        headBar.opacity: fullScreenPlaybackChromeOpacity
        headBar.forceCenterMiddleContent: true

        Maui.Controls.showCSD: true

        headBar.leftContent: [
            ToolButton
            {
                icon.name: (_workspace.sideBar.visible && _workspace.sideBar.position > 0) ? "sidebar-collapse" : "sidebar-expand"
                onClicked: _workspace.sideBar.toggle()
                checked: _workspace.sideBar.visible && _workspace.sideBar.position > 0
                ToolTip.delay: 1000
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: i18n("Toggle sidebar")
            }
        ]

        headBar.middleContent: []

        Item
        {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: _shellPage.headBar.height
            z: 999
            enabled: false
            visible: _shellPage.headBar.visible && !!_playerView.currentVideo.label

            Label
            {
                anchors.centerIn: parent
                width: Math.max(0, parent.width - (Maui.Style.units.gridUnit * 16))
                text: _playerView.currentVideo.label || ""
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideMiddle
                maximumLineCount: 1
            }
        }

        headBar.rightContent: [
            Maui.ToolButtonMenu
            {
                icon.name: "configure"

                MenuItem
                {
                    text: root.visibility === Window.FullScreen ? i18n("Exit Full Screen") : i18n("Full Screen")
                    icon.name: root.visibility === Window.FullScreen ? "view-restore" : "view-fullscreen"
                    onTriggered: root.toggleFullScreen()
                }

                MenuSeparator
                {
                    visible: player.supportsFillMode
                }

                MenuItem
                {
                    visible: player.supportsFillMode
                    text: i18n("Fit to Screen")
                    checkable: true
                    autoExclusive: true
                    checked: player.fillMode === VideoOutput.PreserveAspectFit
                    onTriggered: player.fillMode = VideoOutput.PreserveAspectFit
                }

                MenuItem
                {
                    visible: player.supportsFillMode
                    text: i18n("Crop to Screen")
                    checkable: true
                    autoExclusive: true
                    checked: player.fillMode === VideoOutput.PreserveAspectCrop
                    onTriggered: player.fillMode = VideoOutput.PreserveAspectCrop
                }

                MenuItem
                {
                    visible: player.supportsFillMode
                    text: i18n("Stretch to Screen")
                    checkable: true
                    autoExclusive: true
                    checked: player.fillMode === VideoOutput.Stretch
                    onTriggered: player.fillMode = VideoOutput.Stretch
                }
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

        Maui.SideBarView
        {
            id: _workspace
            anchors.fill: parent
            anchors.topMargin: _shellPage.headBar.height + Maui.Style.space.small
            background: null
            Maui.Theme.colorSet: Maui.Theme.View
            sideBar.preferredWidth: Math.min(root.width * (root.height > root.width ? 0.84 : 0.38), Maui.Style.units.gridUnit * 24)
            sideBar.minimumWidth: Maui.Style.units.gridUnit * 14
            sideBar.maximumWidth: Maui.Style.units.gridUnit * 30
            sideBar.collapsed: root.height > root.width || root.width < Maui.Style.units.gridUnit * 42
            sideBar.autoShow: true
            sideBar.autoHide: true
            sideBar.floats: sideBar.collapsed

            sideBarContent: Maui.Page
            {
                id: _libraryPanel
                readonly property int panelMargin: Maui.Handy.isMobile ? Maui.Style.space.medium : Maui.Style.contentMargins
                anchors.fill: parent
                anchors.margins: panelMargin
                background: Rectangle
                {
                    clip: true
                    color: Maui.Theme.alternateBackgroundColor
                    radius: Maui.Style.radiusV
                    border.color: Maui.Theme.backgroundColor
                    border.width: 1
                }
                clip: true
                opacity: _workspace.sideBar.position
                Behavior on opacity
                {
                    NumberAnimation
                    {
                        duration: 180
                        easing.type: Easing.InOutQuad
                    }
                }
                layer.enabled: true
                Maui.Theme.colorSet: Maui.Theme.Window
                Maui.Theme.inherit: false

                ColumnLayout
                {
                    anchors.fill: parent
                    spacing: 0

                    TabBar
                    {
                        id: _libraryTabs
                        Layout.fillWidth: true
                        z: 2

                        TabButton
                        {
                            text: i18n("Library")
                        }

                        TabButton
                        {
                            text: i18n("Tags")
                        }

                        TabButton
                        {
                            text: i18n("Playlist")
                        }

                        onCurrentIndexChanged:
                        {
                            if (_workspace.sideBar.position === 0)
                                _workspace.sideBar.open()

                            if (currentRoute && currentRoute.forceActiveFocus)
                                Qt.callLater(() => currentRoute.forceActiveFocus())
                        }
                    }

                    Item
                    {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        Item
                        {
                            anchors.fill: parent

                            CollectionsView
                            {
                                id: _collectionsView
                                anchors.fill: parent
                                useInternalChrome: false
                                opacity: collectionsActive ? 1 : 0
                                enabled: collectionsActive
                                z: collectionsActive ? 2 : 0
                            }

                            TagsView
                            {
                                id: _tagsView
                                anchors.fill: parent
                                useInternalChrome: false
                                opacity: tagsActive ? 1 : 0
                                enabled: tagsActive
                                z: tagsActive ? 2 : 0
                            }

                            ColumnLayout
                            {
                                anchors.fill: parent
                                visible: playlistActive
                                spacing: 0

                                RowLayout
                                {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Maui.Style.space.small
                                    Layout.rightMargin: Maui.Style.space.small
                                    Layout.topMargin: Maui.Style.space.small

                                    Item
                                    {
                                        Layout.fillWidth: true
                                    }

                                    ToolButton
                                    {
                                        visible: _playlist.list.count > 0
                                        icon.name: "edit-clear"
                                        text: i18n("Clear")
                                        display: AbstractButton.TextBesideIcon
                                        onClicked: clearQueue()
                                    }
                                }

                                Playlist
                                {
                                    id: _playlist
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                            }
                        }

                    }

                    ToolSeparator
                    {
                        visible: collectionsActive || tagsActive
                        Layout.fillWidth: true
                    }

                    RowLayout
                    {
                        visible: collectionsActive
                        Layout.fillWidth: true
                        Layout.margins: Maui.Style.space.small
                        Layout.preferredHeight: _librarySearchField.implicitHeight
                        Layout.maximumHeight: _librarySearchField.implicitHeight
                        spacing: Maui.Style.space.small

                        ToolButton
                        {
                            visible: collectionsFolderActive
                            Layout.alignment: Qt.AlignVCenter
                            icon.name: "go-previous"
                            onClicked: handleToolbarBack()
                        }

                        ToolSeparator
                        {
                            visible: collectionsFolderActive
                            Layout.alignment: Qt.AlignVCenter
                            bottomPadding: 10
                            topPadding: 10
                        }

                        Maui.SearchField
                        {
                            id: _librarySearchField
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            placeholderText: collectionsFolderActive ? i18n("Search videos") : i18n("Search library")
                            onTextChanged:
                            {
                                if (!suppressToolbarSearchCallbacks)
                                    _collectionsView.search(text)
                            }
                            onCleared:
                            {
                                if (!suppressToolbarSearchCallbacks)
                                    _collectionsView.clearSearch()
                            }
                            Keys.priority: Keys.AfterItem
                            Keys.onReturnPressed: event.accepted = true
                        }

                        ToolSeparator
                        {
                            visible: collectionsFolderActive
                            Layout.alignment: Qt.AlignVCenter
                            bottomPadding: 10
                            topPadding: 10
                        }

                        Maui.ToolButtonMenu
                        {
                            visible: collectionsFolderActive
                            Layout.alignment: Qt.AlignVCenter
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
                        }
                    }

                    RowLayout
                    {
                        visible: tagsActive
                        Layout.fillWidth: true
                        Layout.margins: Maui.Style.space.small
                        Layout.preferredHeight: _tagsSearchField.implicitHeight
                        Layout.maximumHeight: _tagsSearchField.implicitHeight
                        spacing: Maui.Style.space.small

                        ToolButton
                        {
                            visible: tagsFilterActive
                            Layout.alignment: Qt.AlignVCenter
                            icon.name: "go-previous"
                            onClicked: handleToolbarBack()
                        }

                        ToolSeparator
                        {
                            visible: tagsFilterActive
                            Layout.alignment: Qt.AlignVCenter
                            bottomPadding: 10
                            topPadding: 10
                        }

                        Maui.SearchField
                        {
                            id: _tagsSearchField
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            placeholderText: tagsFilterActive ? i18n("Search videos") : i18n("Search tags")
                            onTextChanged:
                            {
                                if (!suppressToolbarSearchCallbacks)
                                    _tagsView.search(text)
                            }
                            onCleared:
                            {
                                if (!suppressToolbarSearchCallbacks)
                                    _tagsView.clearSearch()
                            }
                            Keys.priority: Keys.AfterItem
                            Keys.onReturnPressed: event.accepted = true
                        }

                        ToolSeparator
                        {
                            visible: tagsGridActive
                            Layout.alignment: Qt.AlignVCenter
                            bottomPadding: 10
                            topPadding: 10
                        }

                        Maui.ToolButtonMenu
                        {
                            visible: tagsGridActive
                            Layout.alignment: Qt.AlignVCenter
                            icon.name: "view-sort"

                            MenuItem
                            {
                                text: i18n("Name (A-Z)")
                                checkable: true
                                autoExclusive: true
                                checked: typeof _tagsView.currentSortIndex === "function" && _tagsView.currentSortIndex() === 0
                                onTriggered: _tagsView.applySort(0)
                            }

                            MenuItem
                            {
                                text: i18n("Name (Z-A)")
                                checkable: true
                                autoExclusive: true
                                checked: typeof _tagsView.currentSortIndex === "function" && _tagsView.currentSortIndex() === 1
                                onTriggered: _tagsView.applySort(1)
                            }

                            MenuItem
                            {
                                text: i18n("Date (Newest)")
                                checkable: true
                                autoExclusive: true
                                checked: typeof _tagsView.currentSortIndex === "function" && _tagsView.currentSortIndex() === 2
                                onTriggered: _tagsView.applySort(2)
                            }

                            MenuItem
                            {
                                text: i18n("Date (Oldest)")
                                checkable: true
                                autoExclusive: true
                                checked: typeof _tagsView.currentSortIndex === "function" && _tagsView.currentSortIndex() === 3
                                onTriggered: _tagsView.applySort(3)
                            }
                        }
                    }
                }
            }

            SelectionBar
            {
                id: _selectionBar
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Maui.Style.space.medium
                width: Math.min(parent.width - (Maui.Style.space.medium * 2), implicitWidth)
                maxListHeight: Math.max(0, root.height - _shellPage.headBar.height - (Maui.Style.space.big * 2))
                z: 1000
            }

            Maui.Page
            {
                id: _playerPage
                anchors.fill: parent
                background: null
                headBar.visible: false

                Maui.Controls.showCSD: true

                Keys.enabled: !Maui.Handy.isMobile
                Keys.onPressed: (event) =>
                {
                    if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
                        return

                    switch (event.key) {
                    case Qt.Key_Space:
                    case Qt.Key_K:
                        togglePlayback()
                        break
                    case Qt.Key_Left:
                        seekBy(-5000)
                        break
                    case Qt.Key_Right:
                        seekBy(5000)
                        break
                    case Qt.Key_J:
                        seekBy(-10000)
                        break
                    case Qt.Key_L:
                        seekBy(10000)
                        break
                    case Qt.Key_Up:
                        adjustVolume(5)
                        break
                    case Qt.Key_Down:
                        adjustVolume(-5)
                        break
                    case Qt.Key_M:
                        toggleMute()
                        break
                    case Qt.Key_F:
                        toggleFullScreen()
                        break
                    default:
                        return
                    }

                    event.accepted = true
                }

                PlayerView
                {
                    id: _playerView
                    anchors.fill: parent
                    visible: !_playerHolderLoader.active
                }

                Loader
                {
                    anchors.fill: parent
                    asynchronous: true
                    visible: !_playerHolderLoader.active

                    sourceComponent: RowLayout
                    {
                        MouseArea
                        {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            onDoubleClicked: player.seek(player.position - 5000)
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
                            onDoubleClicked: player.seek(player.position + 5000)
                        }
                    }
                }

                Loader
                {
                    id: _playerHolderLoader
                    anchors.fill: parent
                    active: !_playerView.currentVideo.url || (_playerView.isStopped && playbackHasError())
                    asynchronous: true
                    visible: active
                    sourceComponent: Maui.Holder
                    {
                        emoji: "media-playback-start"
                        title: i18n("Ready to Play")
                        body: playbackHasError()
                              ? playbackErrorString()
                              : i18n("Open a file, add a URL, or choose something from your library to start watching.")
                    }
                }

                floatingFooter: true
                footerMargins: Maui.Style.contentMargins
                footBar.visible: !fullScreenPlaybackChromeAutoHide || fullScreenPlaybackChromeOpacity > 0.01
                footBar.enabled: fullScreenPlaybackChromeOpacity > 0.01
                footBar.opacity: fullScreenPlaybackChromeOpacity

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
                    enabled: !!_playerView.currentVideo.url
                    onMoved: player.seek(_slider.value)
                    spacing: 0
                    focus: true
                }

                footBar.rightContent: [
                    Label
                    {
                        text: Maui.Handy.formatTime(player.position / 1000) + " / " + Maui.Handy.formatTime(player.duration / 1000)
                    },

                    ToolButton
                    {
                        enabled: _volumeSlider.enabled
                        text: volumeGlyph(_playerView.playerVolume || 0)
                        display: AbstractButton.TextOnly
                        padding: 0
                        implicitWidth: Maui.Style.iconSizes.medium
                        implicitHeight: Maui.Style.iconSizes.medium
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: Maui.Style.fontSizes.small
                        font.weight: Font.Black
                        onClicked: toggleMute()
                    },

                    Slider
                    {
                        id: _volumeSlider
                        implicitWidth: Maui.Style.units.gridUnit * 7
                        from: 0
                        to: 100
                        enabled: typeof _playerView.playerVolume === "number"
                        value: enabled ? _playerView.playerVolume : 100
                        onMoved: setPlayerVolume(value)
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
                        enabled: _playlist.list.count > 1
                        onTriggered: playPrevious()
                    }

                    Action
                    {
                        icon.name: player.isPlaying ? "media-playback-pause" : "media-playback-start"
                        enabled: !!_playerView.currentVideo.url
                        onTriggered: player.isPaused ? player.play() : player.pause()
                    }

                    Action
                    {
                        icon.name: "media-playback-stop"
                        enabled: !!_playerView.currentVideo.url
                        onTriggered: stopPlayback()
                    }

                    Action
                    {
                        icon.name: "media-skip-forward"
                        enabled: _playlist.list.count > 1
                        onTriggered: playNext()
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

            playAt(_playlist.list.count - urls.length)
        }
    }

    function searchFieldForIndex(index)
    {
        if (index === 0)
            return _librarySearchField

        if (index === 1)
            return _tagsSearchField

        return null
    }

    function resetSearchField(field)
    {
        suppressToolbarSearchCallbacks = true

        if (field)
            field.text = ""

        suppressToolbarSearchCallbacks = false
    }

    function resetToolbarSearch(index)
    {
        const effectiveIndex = index === undefined ? _libraryTabs.currentIndex : index
        resetSearchField(searchFieldForIndex(effectiveIndex))
    }

    function handleToolbarBack()
    {
        if ((collectionsFolderActive || tagsFilterActive) && currentRoute && currentRoute.goBack) {
            resetToolbarSearch()
            currentRoute.goBack()
            currentRoute.forceActiveFocus()
        }
    }

    function showLibrarySection(index)
    {
        if (_libraryTabs.currentIndex !== index)
            _libraryTabs.currentIndex = index

        if (_workspace.sideBar.position === 0)
            _workspace.sideBar.open()

        if (currentRoute && currentRoute.forceActiveFocus)
            Qt.callLater(() => currentRoute.forceActiveFocus())
    }

    function showGallery()
    {
        showCollections()
    }

    function showCollections()
    {
        showLibrarySection(0)
    }

    function showTags()
    {
        showLibrarySection(1)
    }

    function showQueue()
    {
        showLibrarySection(2)
    }

    function openFolder(url, filters)
    {
        showCollections()
        _collectionsView.openFolder(url, filters)
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
        const existingIndex = indexOfQueuedItem(item.url)

        if (existingIndex >= 0) {
            playAt(existingIndex)
            return
        }

        queue(item)
        playAt(_playlist.list.count - 1)
    }

    function playAt(index)
    {
        if ((index < _playlist.list.count) && (index > -1))
        {
            _playerView.currentVideoIndex = index
            _playerView.currentVideo = _playlist.model.get(index)

            _playerView.play()
            _playerPage.forceActiveFocus()
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

    function queueItemsIfMissing(items)
    {
        let added = 0

        for (const item of items) {
            if (!item || !item.url || indexOfQueuedItem(item.url) >= 0)
                continue

            queue(item)
            added++
        }

        return added
    }

    function queue(item)
    {
        _playlist.append(item)
    }

    function clearQueue()
    {
        _playlist.list.clear()
        stopPlayback()
    }

    function togglePlayback()
    {
        if (!_playerView.currentVideo.url)
            return

        if (player.playbackState === MediaPlayer.PlayingState)
            player.pause()
        else
            player.play()
    }

    function seekBy(offset)
    {
        if (!_playerView.currentVideo.url)
            return

        const maxPosition = Math.max(0, player.duration || 0)
        const targetPosition = player.position + offset
        const nextPosition = maxPosition > 0
                           ? Math.max(0, Math.min(maxPosition, targetPosition))
                           : Math.max(0, targetPosition)

        player.seek(nextPosition)
    }

    function setPlayerVolume(value)
    {
        if (typeof _playerView.playerVolume !== "number")
            return

        const clamped = Math.max(0, Math.min(100, Math.round(value)))

        if (clamped > 0)
            lastAudibleVolume = clamped

        _playerView.playerVolume = clamped
    }

    function adjustVolume(delta)
    {
        if (typeof _playerView.playerVolume !== "number")
            return

        setPlayerVolume((_playerView.playerVolume || 0) + delta)
    }

    function toggleMute()
    {
        if (typeof _playerView.playerVolume !== "number")
            return

        if ((_playerView.playerVolume || 0) > 0)
            setPlayerVolume(0)
        else
            setPlayerVolume(lastAudibleVolume > 0 ? lastAudibleVolume : 100)
    }

    function volumeGlyph(volume)
    {
        if (volume <= 0)
            return "\uf6a9"

        if (volume < 50)
            return "\uf027"

        return "\uf028"
    }

    function playbackHasError()
    {
        return !!(_playerView && _playerView.hasError)
    }

    function playbackErrorString()
    {
        return playbackHasError() ? _playerView.lastErrorString : ""
    }

    function indexOfQueuedItem(url)
    {
        for (let i = 0; i < _playlist.list.count; ++i) {
            const queuedItem = _playlist.model.get(i)

            if (queuedItem && queuedItem.url === url)
                return i
        }

        return -1
    }

    function stopPlayback()
    {
        if (_playerView.stop)
            _playerView.stop()

        _playerView.currentVideoIndex = -1
        _playerView.currentVideo = ({})
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

    function openUrlDialog()
    {
        const dialog = _openUrlDialogComponent.createObject(root)
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

        _playerView.play()
        _playerPage.forceActiveFocus()
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
