import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui

Maui.SelectionBar
{
    id: control

    readonly property var windowRoot: ApplicationWindow.window
    property bool selectionModeActivationQueued: false

    display: ToolButton.IconOnly

    onCountChanged:
    {
        if (!windowRoot)
            return

        if (count > 0) {
            if (!windowRoot.selectionMode && !selectionModeActivationQueued) {
                selectionModeActivationQueued = true
                Qt.callLater(function()
                {
                    selectionModeActivationQueued = false

                    if (windowRoot && control.count > 0)
                        windowRoot.selectionMode = true
                })
            }
        } else {
            selectionModeActivationQueued = false
            windowRoot.selectionMode = false
        }
    }

    onExitClicked:
    {
        selectionModeActivationQueued = false
        clear()

        if (windowRoot)
            windowRoot.selectionMode = false
    }

    listDelegate: Maui.ListBrowserDelegate
    {
        width: Maui.Style.iconSizes.big + Maui.Style.space.medium
        height: Maui.Style.iconSizes.big + Maui.Style.space.small
        label1.text: ""
        label2.text: ""
        tooltipText: model.label || model.url
        imageSource: model.thumbnail || model.preview || ""
        iconSource: model.icon
        iconSizeHint: Maui.Style.iconSizes.big
        checked: true
        checkable: true
        background: Item {}
        template.fillMode: Image.PreserveAspectCrop

        onToggled: control.removeAtIndex(index)
    }

    Action
    {
        text: i18n("Play")
        icon.name: "media-playback-start"
        enabled: control.count > 0
        onTriggered:
        {
            if (!windowRoot)
                return

            windowRoot.playItems(Array.from(control.items))
            control.clear()
        }
    }

    Action
    {
        text: i18n("Add to Playlist")
        icon.name: "media-playlist-append"
        enabled: control.count > 0
        onTriggered:
        {
            if (!windowRoot)
                return

            windowRoot.queueItemsIfMissing(Array.from(control.items))
            control.clear()
        }
    }

    Action
    {
        text: i18n("Remove")
        icon.name: "edit-delete"
        enabled: control.count > 0
        Maui.Controls.status: Maui.Controls.Negative
        onTriggered:
        {
            if (!windowRoot)
                return

            windowRoot.removeFiles(control.uris)
        }
    }
}
