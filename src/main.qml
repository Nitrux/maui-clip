import QtQuick
import QtCore
import QtQml
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
    property real visualPlayerPosition: 0
    property real visualPlayerPositionSyncValue: 0
    property double visualPlayerPositionSyncTimestamp: 0
    property real cachedPlayerDuration: 0
    property bool reachedEndOfFile: false
    property var shuffledPlaybackHistory: []
    property int shuffledPlaybackHistoryPosition: -1
    readonly property int replayModeOff: 0
    readonly property int replayModeOne: 1
    readonly property int replayModeAll: 2

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
        property bool shufflePlayback: false
        property int replayMode: 0
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
                id: _displayOptionsMenu
                icon.name: "configure"
                readonly property bool trackOptionsVisible: _playerView.hasSubtitleTracks || _playerView.hasAudioTracks

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

                MenuSeparator
                {
                    visible: _displayOptionsMenu.trackOptionsVisible
                    implicitHeight: visible ? 1 + (Maui.Style.space.tiny * 2) : 0
                    height: implicitHeight
                }

                MenuItem
                {
                    visible: _playerView.hasSubtitleTracks
                    implicitHeight: visible ? contentItem.implicitHeight + topPadding + bottomPadding : 0
                    height: implicitHeight
                    text: i18n("Subtitles")
                    onTriggered: _playerView.openSubtitlesDialog()
                }

                MenuItem
                {
                    visible: _playerView.hasAudioTracks
                    implicitHeight: visible ? contentItem.implicitHeight + topPadding + bottomPadding : 0
                    height: implicitHeight
                    text: i18n("Audio Tracks")
                    onTriggered: _playerView.openAudioTracksDialog()
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
            background: null
            Maui.Theme.colorSet: Maui.Theme.View
            readonly property real topChromeOffset: _shellPage.headBar.height + Maui.Style.space.small
            sideBar.preferredWidth: Math.min(root.width * (root.height > root.width ? 0.84 : 0.38), Maui.Style.units.gridUnit * 24)
            sideBar.minimumWidth: Maui.Style.units.gridUnit * 14
            sideBar.maximumWidth: Maui.Style.units.gridUnit * 30
            sideBar.collapsed: root.height > root.width || root.width < Maui.Style.units.gridUnit * 42
            sideBar.autoShow: true
            sideBar.autoHide: true
            sideBar.floats: true
            sideBar.height: Math.max(0, _workspace.height - _playerPage.footBar.height - Maui.Style.space.small)

            sideBarContent: Maui.Page
            {
                id: _libraryPanel
                readonly property int panelMargin: Maui.Handy.isMobile ? Maui.Style.space.medium : Maui.Style.contentMargins
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: panelMargin
                anchors.rightMargin: panelMargin
                anchors.bottomMargin: panelMargin
                anchors.topMargin: panelMargin + _workspace.topChromeOffset
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
                            onDoubleClicked:
                            {
                                seekBy(-5000)
                                _seekBackwardOverlay.restart()
                            }
                        }

                        MouseArea
                        {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            onClicked:
                            {
                                if (player.playbackState === MediaPlayer.PlayingState) {
                                    player.pause()
                                    _playbackStateOverlay.showPause()
                                } else {
                                    startPlayback()
                                    _playbackStateOverlay.showPlay()
                                }
                            }
                            onDoubleClicked: root.toggleFullScreen()
                        }

                        MouseArea
                        {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            onDoubleClicked:
                            {
                                seekBy(5000)
                                _seekForwardOverlay.restart()
                            }
                        }
                    }
                }

                Item
                {
                    anchors.fill: parent
                    visible: !_playerHolderLoader.active
                    enabled: false

                    Rectangle
                    {
                        id: _seekBackwardOverlay
                        width: Math.min(parent.width * 0.12, Maui.Style.units.gridUnit * 5)
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Math.max(parent.width * 0.08, Maui.Style.units.gridUnit * 2)
                        color: Qt.rgba(0.08, 0.09, 0.15, 0.68)
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1
                        opacity: 0
                        scale: 0.84
                        visible: opacity > 0

                        Column
                        {
                            anchors.centerIn: parent
                            spacing: Maui.Style.space.tiny

                            Label
                            {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "\uf04a"
                                font.family: "Font Awesome 6 Free Solid"
                                font.pixelSize: Maui.Style.fontSizes.big
                                font.weight: Font.Black
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label
                            {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: i18n("-5s")
                                font.pixelSize: Maui.Style.fontSizes.small
                                font.weight: Font.DemiBold
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        SequentialAnimation on opacity
                        {
                            id: _seekBackwardOpacityAnimation
                            running: false

                            NumberAnimation
                            {
                                to: 1
                                duration: 120
                                easing.type: Easing.OutQuad
                            }

                            PauseAnimation
                            {
                                duration: 240
                            }

                            NumberAnimation
                            {
                                to: 0
                                duration: 210
                                easing.type: Easing.InQuad
                            }
                        }

                        SequentialAnimation on scale
                        {
                            id: _seekBackwardScaleAnimation
                            running: false

                            NumberAnimation
                            {
                                to: 1
                                duration: 160
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.08
                            }

                            PauseAnimation
                            {
                                duration: 200
                            }

                            NumberAnimation
                            {
                                to: 0.9
                                duration: 210
                                easing.type: Easing.InQuad
                            }
                        }

                        function restart()
                        {
                            opacity = 0
                            scale = 0.84
                            _seekBackwardOpacityAnimation.restart()
                            _seekBackwardScaleAnimation.restart()
                        }
                    }

                    Rectangle
                    {
                        id: _seekForwardOverlay
                        width: Math.min(parent.width * 0.12, Maui.Style.units.gridUnit * 5)
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Math.max(parent.width * 0.08, Maui.Style.units.gridUnit * 2)
                        color: Qt.rgba(0.08, 0.09, 0.15, 0.68)
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1
                        opacity: 0
                        scale: 0.84
                        visible: opacity > 0

                        Column
                        {
                            anchors.centerIn: parent
                            spacing: Maui.Style.space.tiny

                            Label
                            {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "\uf04e"
                                font.family: "Font Awesome 6 Free Solid"
                                font.pixelSize: Maui.Style.fontSizes.big
                                font.weight: Font.Black
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label
                            {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: i18n("+5s")
                                font.pixelSize: Maui.Style.fontSizes.small
                                font.weight: Font.DemiBold
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        SequentialAnimation on opacity
                        {
                            id: _seekForwardOpacityAnimation
                            running: false

                            NumberAnimation
                            {
                                to: 1
                                duration: 120
                                easing.type: Easing.OutQuad
                            }

                            PauseAnimation
                            {
                                duration: 240
                            }

                            NumberAnimation
                            {
                                to: 0
                                duration: 210
                                easing.type: Easing.InQuad
                            }
                        }

                        SequentialAnimation on scale
                        {
                            id: _seekForwardScaleAnimation
                            running: false

                            NumberAnimation
                            {
                                to: 1
                                duration: 160
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.08
                            }

                            PauseAnimation
                            {
                                duration: 200
                            }

                            NumberAnimation
                            {
                                to: 0.9
                                duration: 210
                                easing.type: Easing.InQuad
                            }
                        }

                        function restart()
                        {
                            opacity = 0
                            scale = 0.84
                            _seekForwardOpacityAnimation.restart()
                            _seekForwardScaleAnimation.restart()
                        }
                    }

                    Rectangle
                    {
                        id: _playbackStateOverlay
                        property string iconGlyph: "\uf04b"
                        property string statusText: i18n("Play")
                        width: Math.min(parent.width * 0.14, Maui.Style.units.gridUnit * 6)
                        height: width
                        radius: width / 2
                        anchors.centerIn: parent
                        color: Qt.rgba(0.08, 0.09, 0.15, 0.72)
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1
                        opacity: 0
                        scale: 0.84
                        visible: opacity > 0

                        Column
                        {
                            anchors.centerIn: parent
                            spacing: Maui.Style.space.tiny

                            Label
                            {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: _playbackStateOverlay.iconGlyph
                                font.family: "Font Awesome 6 Free Solid"
                                font.pixelSize: Maui.Style.fontSizes.big
                                font.weight: Font.Black
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label
                            {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: _playbackStateOverlay.statusText
                                font.pixelSize: Maui.Style.fontSizes.small
                                font.weight: Font.DemiBold
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        SequentialAnimation on opacity
                        {
                            id: _playbackStateOpacityAnimation
                            running: false

                            NumberAnimation
                            {
                                to: 1
                                duration: 110
                                easing.type: Easing.OutQuad
                            }

                            PauseAnimation
                            {
                                duration: 220
                            }

                            NumberAnimation
                            {
                                to: 0
                                duration: 180
                                easing.type: Easing.InQuad
                            }
                        }

                        SequentialAnimation on scale
                        {
                            id: _playbackStateScaleAnimation
                            running: false

                            NumberAnimation
                            {
                                to: 1
                                duration: 150
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.06
                            }

                            PauseAnimation
                            {
                                duration: 180
                            }

                            NumberAnimation
                            {
                                to: 0.9
                                duration: 180
                                easing.type: Easing.InQuad
                            }
                        }

                        function restart()
                        {
                            opacity = 0
                            scale = 0.84
                            _playbackStateOpacityAnimation.restart()
                            _playbackStateScaleAnimation.restart()
                        }

                        function showPlay()
                        {
                            iconGlyph = "\uf04b"
                            statusText = i18n("Play")
                            restart()
                        }

                        function showPause()
                        {
                            iconGlyph = "\uf04c"
                            statusText = i18n("Pause")
                            restart()
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
                    to: cachedPlayerDuration || player.duration
                    live: true
                    Layout.preferredHeight: 22
                    enabled: !!_playerView.currentVideo.url
                    spacing: 0
                    focus: true

                    Binding on value
                    {
                        when: !_slider.pressed
                        value: displayedPlayerPosition()
                        restoreMode: Binding.RestoreBindingOrValue
                    }

                    onPressedChanged:
                    {
                        if (!pressed) {
                            syncVisualPlayerPosition(_slider.value)
                            player.seek(_slider.value)
                        }
                    }

                    MouseArea
                    {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                        z: 10

                        onWheel: function(wheel)
                        {
                            wheel.accepted = true
                        }
                    }
                }

                footBar.rightContent: [
                    Label
                    {
                        text: Maui.Handy.formatTime(Math.round(displayedPlayerPosition() / 1000)) + " / " + Maui.Handy.formatTime(Math.round(player.duration / 1000))
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
                        stepSize: 5
                        enabled: typeof _playerView.playerVolume === "number"
                        value: enabled ? _playerView.playerVolume : 100
                        onMoved: setPlayerVolume(value)

                        MouseArea
                        {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            hoverEnabled: true
                            z: 10

                            onWheel: function(wheel)
                            {
                                if (!_volumeSlider.enabled)
                                    return

                                const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y
                                if (delta === 0)
                                    return

                                setPlayerVolume(_volumeSlider.value + (delta > 0 ? _volumeSlider.stepSize : -_volumeSlider.stepSize))
                                wheel.accepted = true
                            }
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
                        enabled: _playlist.list.count > 1
                        onTriggered: playPrevious()
                    }

                    Action
                    {
                        icon.name: player.isPlaying ? "media-playback-pause" : "media-playback-start"
                        enabled: !!_playerView.currentVideo.url
                        onTriggered: player.isPlaying ? player.pause() : startPlayback()
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

    Connections
    {
        target: _playerView.player
        ignoreUnknownSignals: true

        function onPositionChanged()
        {
            syncVisualPlayerPosition(player.position)
        }

        function onDurationChanged()
        {
            if (player.duration > 0)
                cachedPlayerDuration = player.duration
            syncVisualPlayerPosition(player.position)
        }

        function onPlaybackStateChanged()
        {
            syncVisualPlayerPosition(player.position)
        }

        function onStatusChanged()
        {
            if (player.status === MediaPlayer.EndOfMedia)
                syncVisualPlayerPosition(cachedPlayerDuration)
            else
                syncVisualPlayerPosition(player.position)
        }

        function onEndOfFile()
        {
            reachedEndOfFile = true
            visualPlayerPosition = cachedPlayerDuration
            handlePlaybackEnded()
        }

        function onFileLoaded()
        {
            reachedEndOfFile = false
        }
    }

    Connections
    {
        target: settings

        function onReplayModeChanged()
        {
            applyReplayModeToPlayer()
        }
    }

    Timer
    {
        interval: 33
        repeat: true
        running: !!_playerView.currentVideo.url && player.playbackState === MediaPlayer.PlayingState && !_slider.pressed
        onTriggered:
        {
            const elapsed = Date.now() - visualPlayerPositionSyncTimestamp
            const projected = visualPlayerPositionSyncValue + elapsed
            visualPlayerPosition = Math.max(0, Math.min(cachedPlayerDuration || 0, projected))
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

    function syncVisualPlayerPosition(position)
    {
        const duration = cachedPlayerDuration || player.duration || 0
        const nextPosition = Math.max(0, Math.min(duration, position || 0))
        visualPlayerPosition = nextPosition
        visualPlayerPositionSyncValue = nextPosition
        visualPlayerPositionSyncTimestamp = Date.now()
    }

    function displayedPlayerPosition()
    {
        if (_slider.pressed)
            return _slider.value

        if (reachedEndOfFile)
            return cachedPlayerDuration

        return visualPlayerPosition
    }

    function currentQueuedVideoIsActive()
    {
        if (_playerView.currentVideoIndex < 0 || _playerView.currentVideoIndex >= _playlist.list.count)
            return false

        const currentQueuedItem = _playlist.model.get(_playerView.currentVideoIndex)
        return !!currentQueuedItem && currentQueuedItem.url === _playerView.currentVideo.url
    }

    function resetShuffleHistory()
    {
        shuffledPlaybackHistory = []
        shuffledPlaybackHistoryPosition = -1
    }

    function rememberShuffledPlayback(url)
    {
        if (!url)
            return

        let history = shuffledPlaybackHistory.slice()

        if (shuffledPlaybackHistoryPosition < history.length - 1)
            history = history.slice(0, shuffledPlaybackHistoryPosition + 1)

        if (history.length === 0 || history[history.length - 1] !== url)
            history.push(url)

        shuffledPlaybackHistory = history
        shuffledPlaybackHistoryPosition = history.length - 1
    }

    function removeFromShuffleHistory(url)
    {
        if (!url || shuffledPlaybackHistory.length === 0)
            return

        const history = []
        let nextHistoryPosition = shuffledPlaybackHistoryPosition

        for (let i = 0; i < shuffledPlaybackHistory.length; ++i) {
            if (shuffledPlaybackHistory[i] === url) {
                if (i <= nextHistoryPosition)
                    nextHistoryPosition--

                continue
            }

            history.push(shuffledPlaybackHistory[i])
        }

        shuffledPlaybackHistory = history
        shuffledPlaybackHistoryPosition = Math.max(-1, Math.min(nextHistoryPosition, history.length - 1))
    }

    function randomQueuedIndex(excludedIndex)
    {
        if (_playlist.list.count <= 0)
            return -1

        if (_playlist.list.count === 1)
            return 0

        let nextIndex = excludedIndex

        while (nextIndex === excludedIndex)
            nextIndex = Math.floor(Math.random() * _playlist.list.count)

        return nextIndex
    }

    function restartCurrentVideo()
    {
        if (!_playerView.currentVideo.url)
            return false

        if (_playerView.restart)
            _playerView.restart()
        else {
            _playerView.seek(0)
            _playerView.play()
        }

        _playerPage.forceActiveFocus()
        return true
    }

    function startPlayback()
    {
        if (!_playerView.currentVideo.url)
            return false

        if (player.status === MediaPlayer.EndOfMedia)
            return restartCurrentVideo()

        player.play()
        return true
    }

    function applyReplayModeToPlayer()
    {
        if (!_playerView || !_playerView.player || !_playerView.player.setProperty)
            return

        _playerView.player.setProperty("loop-file", settings.replayMode === replayModeOne ? "inf" : "no")
    }

    function handlePlaybackEnded()
    {
        if (!_playerView.currentVideo.url)
            return

        if (settings.replayMode === replayModeOne) {
            applyReplayModeToPlayer()
            return
        }

        if (!currentQueuedVideoIsActive())
            return

        const shouldWrap = settings.replayMode === replayModeAll

        Qt.callLater(function()
        {
            if (!_playerView.currentVideo.url || !currentQueuedVideoIsActive())
                return

            const advanced = playNext({ wrap: shouldWrap })

            if (!advanced && !shouldWrap && _playerView.stop)
                _playerView.stop()
        })
    }

    function playNext(options)
    {
        const playbackOptions = options || {}
        const wrap = playbackOptions.wrap === undefined ? true : playbackOptions.wrap

        if (!currentQueuedVideoIsActive())
            return false

        if (settings.shufflePlayback) {
            if (_playlist.list.count === 1)
                return wrap ? playAt(0) : false

            const nextHistoryIndex = shuffledPlaybackHistoryPosition + 1

            if (nextHistoryIndex >= 0 && nextHistoryIndex < shuffledPlaybackHistory.length) {
                const nextHistoryItemIndex = indexOfQueuedItem(shuffledPlaybackHistory[nextHistoryIndex])

                if (nextHistoryItemIndex >= 0) {
                    shuffledPlaybackHistoryPosition = nextHistoryIndex
                    return playAt(nextHistoryItemIndex, { skipHistory: true })
                }
            }

            return playAt(randomQueuedIndex(_playerView.currentVideoIndex))
        }

        const nextIndex = _playerView.currentVideoIndex + 1

        if (nextIndex < _playlist.list.count)
            return playAt(nextIndex)

        if (wrap)
            return playAt(0)

        return false
    }

    function playPrevious()
    {
        if (!currentQueuedVideoIsActive())
            return false

        if (settings.shufflePlayback) {
            const previousHistoryIndex = shuffledPlaybackHistoryPosition - 1

            if (previousHistoryIndex >= 0) {
                const previousHistoryItemIndex = indexOfQueuedItem(shuffledPlaybackHistory[previousHistoryIndex])

                if (previousHistoryItemIndex >= 0) {
                    shuffledPlaybackHistoryPosition = previousHistoryIndex
                    return playAt(previousHistoryItemIndex, { skipHistory: true })
                }
            }

            return playAt(randomQueuedIndex(_playerView.currentVideoIndex))
        }

        const previousIndex = _playerView.currentVideoIndex - 1 >= 0 ? _playerView.currentVideoIndex - 1 : _playlist.list.count - 1
        return playAt(previousIndex)
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

    function playAt(index, options)
    {
        const playbackOptions = options || {}

        if ((index < _playlist.list.count) && (index > -1))
        {
            const queuedItem = _playlist.model.get(index)

            if (!playbackOptions.skipHistory && queuedItem && queuedItem.url)
                rememberShuffledPlayback(queuedItem.url)

            _playerView.currentVideoIndex = index
            _playerView.currentVideo = queuedItem

            applyReplayModeToPlayer()
            _playerView.play()
            _playerPage.forceActiveFocus()
            return true
        }

        return false
    }

    function playItems(items)
    {
        resetShuffleHistory()
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

    function removeQueuedItem(index)
    {
        if (index < 0 || index >= _playlist.list.count)
            return false

        const removedItem = _playlist.model.get(index)
        const removedUrl = removedItem ? removedItem.url : ""
        const removedCurrentItem = index === _playerView.currentVideoIndex
        const previousIndex = _playerView.currentVideoIndex

        if (removedUrl)
            removeFromShuffleHistory(removedUrl)

        _playlist.list.remove(index)

        if (_playlist.list.count === 0) {
            resetShuffleHistory()
            stopPlayback()
            return true
        }

        if (!removedCurrentItem) {
            if (index < previousIndex)
                _playerView.currentVideoIndex = previousIndex - 1

            return true
        }

        const replacementIndex = Math.min(index, _playlist.list.count - 1)
        const replacementItem = _playlist.model.get(replacementIndex)

        _playerView.currentVideoIndex = replacementIndex
        _playerView.currentVideo = replacementItem || ({})
        applyReplayModeToPlayer()
        startPlayback()
        _playerPage.forceActiveFocus()
        return true
    }

    function clearQueue()
    {
        resetShuffleHistory()
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
            startPlayback()
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

        resetShuffleHistory()
        _playerView.currentVideoIndex = -1
        _playerView.currentVideo = ({ label: url, url: url, preview: "" })

        applyReplayModeToPlayer()
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
