import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB
import org.maui.clip as Clip

import ".."

Maui.Page
{
    id: control

    background: null

    property alias list: _collectionList
    property alias listModel: _collectionModel
    property alias model: _browser.model
    property alias currentIndex: _browser.currentIndex
    property alias selectionMode: _browser.selectionMode

    clip: true

    footBar.visible: true
    footBar.leftContent: [
        ToolButton
        {
            icon.name: "document-open"
            ToolTip.visible: hovered
            ToolTip.text: i18n("Open playlist from file")
            onClicked: openList()
        },

        ToolButton
        {
            enabled: list.count > 0
            icon.name: "document-save"
            ToolTip.visible: hovered
            ToolTip.text: i18n("Save playlist to file")
            onClicked: saveList()
        },

        ToolSeparator
        {
            topPadding: Maui.Style.space.small
            bottomPadding: Maui.Style.space.small
        },

        ToolButton
        {
            enabled: list.count > 0
            icon.name: settings.replayMode === root.replayModeAll
                       ? "media-playlist-repeat"
                       : settings.replayMode === root.replayModeOne
                         ? "media-repeat-one"
                         : "media-repeat-none"
            ToolTip.visible: hovered
            ToolTip.text: settings.replayMode === root.replayModeAll
                          ? i18n("Repeat: All")
                          : settings.replayMode === root.replayModeOne
                            ? i18n("Repeat: One")
                            : i18n("Repeat: Off")
            onClicked: settings.replayMode = settings.replayMode === root.replayModeAll
                       ? root.replayModeOff : root.replayModeAll
        },

        ToolButton
        {
            enabled: list.count > 0
            checkable: true
            checked: settings.shufflePlayback
            icon.name: "media-playlist-shuffle"
            ToolTip.visible: hovered
            ToolTip.text: checked ? i18n("Playback mode: Shuffle") : i18n("Playback mode: Normal")
            onClicked: settings.shufflePlayback = !settings.shufflePlayback
        }]

    footBar.rightContent: ToolButton
    {
        enabled: list.count > 0
        icon.name: "edit-clear"
        ToolTip.visible: hovered
        ToolTip.text: i18n("Clear playlist")
        onClicked: root.clearQueue()
    }

    Maui.ListBrowser
    {
        id: _browser
        anchors.fill: parent
        clip: true

        holder.visible: list.count === 0
        holder.label1.width: Math.min(width - (Maui.Style.space.big * 2), Maui.Style.units.gridUnit * 12)
        holder.label2.width: holder.label1.width
        holder.emoji: "media-playlist-append"
        holder.title: i18n("Playlist is Empty")
        holder.body: i18n("Play videos from your library to build a playlist.")

        Connections
        {
            target: _playerView

            function onCurrentVideoIndexChanged()
            {
                if (_playerView.currentVideoIndex >= 0)
                    control.currentIndex = _playerView.currentVideoIndex
            }
        }

        model: Maui.BaseModel
        {
            id: _collectionModel
            recursiveFilteringEnabled: true
            sortCaseSensitivity: Qt.CaseInsensitive
            filterCaseSensitivity: Qt.CaseInsensitive
            list: Clip.Videos
            {
                id: _collectionList
            }
        }

        ItemMenu
        {
            id: _menu
            index: control.currentIndex
            model: control.model
        }

        delegate: Maui.ListBrowserDelegate
        {
            id: _listDelegate
            width: ListView.view.width

            isCurrentItem: ListView.isCurrentItem
            draggable: true
            tooltipText: model.url

            label1.text: model.label
            label2.text: Qt.formatDateTime(new Date(model.modified), "d MMM yyyy")
            imageSource: model.thumbnail || model.preview || ""
            template.fillMode: Image.PreserveAspectCrop

            ToolButton
            {
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth
                visible: (Maui.Handy.isTouch ? true : _listDelegate.hovered)
                icon.name: "edit-clear"
                onClicked: root.removeQueuedItem(index)

                opacity: _listDelegate.hovered ? 0.8 : 0.6
            }

            onToggled: _browser.itemsSelected([index])

            onClicked: (mouse) =>
            {
                control.currentIndex = index

                if (selectionMode || (mouse.button == Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier))) {
                    _browser.itemsSelected([index])
                } else if (Maui.Handy.singleClick) {
                    playAt(index)
                }
            }

            onDoubleClicked:
            {
                control.currentIndex = index

                if (!Maui.Handy.singleClick && !selectionMode)
                    playAt(index)
            }
        }
    }

    function append(item)
    {
        control.list.append(item)
    }

    function sanitizedToastPath(path)
    {
        const rawPath = String(path || "")
        const localPath = rawPath.startsWith("file://") ? rawPath.slice(7) : rawPath

        try {
            return decodeURIComponent(localPath)
        } catch (error) {
            return localPath
        }
    }

    function openList()
    {
        const props = ({
            "mode": FB.FileDialog.Modes.Open,
            "singleSelection": true,
            "currentPath": FB.FM.homePath(),
            "callback": function(paths)
            {
                if (!paths || paths.length === 0)
                    return

                root.stopPlayback()
                const ok = control.list.importM3U(paths[0])
                root.resetShuffleHistory()
                const toastPath = sanitizedToastPath(paths[0])
                if (ok)
                    Maui.App.rootComponent.notify("dialog-information", i18n("Playlist loaded"), toastPath)
                else
                    Maui.App.rootComponent.notify("dialog-error", i18n("Could not open playlist"), toastPath)
            }
        })

        const dialog = _fileDialogComponent.createObject(root, props)
        dialog.open()
    }

    function saveList()
    {
        if (list.count <= 0)
            return

        const suggested = "Clip Playlist " + Qt.formatDateTime(new Date(), "yyyy-MM-dd hh-mm-ss") + ".m3u"
        const props = ({
            "mode": FB.FileDialog.Modes.Save,
            "singleSelection": true,
            "currentPath": FB.FM.homePath(),
            "suggestedFileName": suggested,
            "callback": function(paths)
            {
                if (!paths || paths.length === 0)
                    return

                const ok = control.list.exportM3U(paths[0])
                const toastPath = sanitizedToastPath(paths[0])
                if (ok)
                    Maui.App.rootComponent.notify("dialog-information", i18n("Playlist saved"), toastPath)
                else
                    Maui.App.rootComponent.notify("dialog-error", i18n("Could not save playlist"), toastPath)
            }
        })

        const dialog = _fileDialogComponent.createObject(root, props)
        dialog.open()
    }

    Component
    {
        id: _fileDialogComponent
        FB.FileDialog
        {
            browser.settings.filters: ["*.m3u", "*.m3u8"]
            onClosed: destroy()
        }
    }
}
