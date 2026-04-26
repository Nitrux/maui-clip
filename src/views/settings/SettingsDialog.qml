import QtQuick
import QtQml

import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui

import org.maui.clip as Clip

Maui.SettingsDialog
{
    id: control

    Maui.SectionGroup
    {
        title: i18n("General")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Hardware Decoding")
            label2.text: i18n("Use hardware acceleration for playback when available.")

            Switch
            {
                checkable: true
                checked: settings.hardwareDecoding
                onToggled: settings.hardwareDecoding = !settings.hardwareDecoding
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Hide Player Chrome in Full Screen")
            label2.text: i18n("Hide the header and playback controls while watching videos in full screen.")

            Switch
            {
                checkable: true
                checked: settings.hidePlayerChromeInFullScreen
                onToggled: settings.hidePlayerChromeInFullScreen = !settings.hidePlayerChromeInFullScreen
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Shuffle Playback")
            label2.text: i18n("Play a random queued video when moving forward or backward through the playlist.")

            Switch
            {
                checkable: true
                checked: settings.shufflePlayback
                onToggled: settings.shufflePlayback = checked
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Replay")
            label2.text: i18n("Choose what happens after the current video finishes.")

            ComboBox
            {
                implicitWidth: Math.max(Maui.Style.units.gridUnit * 7, contentItem.implicitWidth + leftPadding + rightPadding)
                model: [
                    i18n("Off"),
                    i18n("Replay One"),
                    i18n("Replay All")
                ]
                currentIndex: settings.replayMode
                onActivated: (index) => settings.replayMode = index
            }
        }
    }

    Maui.SectionGroup
    {
        title: i18n("Sources")

        ColumnLayout
        {
            Layout.fillWidth: true
            spacing: Maui.Style.space.medium

            Repeater
            {
                id: _sourcesList
                model: Clip.Clip.sourcesModel

                delegate: Maui.ListDelegate
                {
                    Layout.fillWidth: true
                    template.iconSource: modelData.icon
                    template.iconSizeHint: Maui.Style.iconSizes.small
                    template.label1.text: modelData.label
                    template.label2.text: modelData.path || modelData.url

                    template.content: ToolButton
                    {
                        icon.name: "edit-clear"
                        flat: true
                        onClicked:
                        {
                            confirmationDialog.sourceUrl = modelData.url
                            confirmationDialog.sourceLabel = modelData.path || modelData.url
                            confirmationDialog.open()
                        }
                    }
                }
            }

            Button
            {
                Layout.fillWidth: true
                text: i18n("Add Source")

                onClicked:
                {
                    const props = ({
                        'browser.settings.onlyDirs': true,
                        'callback': function(urls)
                        {
                            Clip.Clip.addSources(urls)
                        }
                    })

                    const dialog = fmDialogComponent.createObject(root, props)
                    dialog.open()
                }
            }
        }
    }

    Maui.InfoDialog
    {
        id: confirmationDialog
        property string sourceUrl: ""
        property string sourceLabel: ""

        title: i18n("Remove Source")
        message: i18n("Are you sure you want to remove the source:\n%1", sourceLabel)
        template.iconSource: "emblem-warning"

        standardButtons: Dialog.Ok | Dialog.Cancel

        onAccepted:
        {
            if (sourceUrl.length > 0)
                Clip.Clip.removeSources(sourceUrl)

            confirmationDialog.close()
        }

        onRejected: confirmationDialog.close()
    }
}
