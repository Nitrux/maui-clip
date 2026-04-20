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
            label1.text: i18n("Volume Step")

            SpinBox
            {
                value: settings.volumeStep
                from: 0
                to: 20
                onValueChanged: settings.volumeStep = value
            }
        }
    }

    Maui.SectionGroup
    {
        title: i18n("Playback")
        enabled: Clip.Clip.mpvAvailable

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
    }

    Maui.SectionGroup
    {
        title: i18n("Audio")
        enabled: Clip.Clip.mpvAvailable

        Maui.SectionItem
        {
            label1.text: i18n("Preferred Language")
            label2.text: i18n("Preferred language if available.")

            TextField
            {
                Layout.fillWidth: true
                text: settings.preferredLanguage
                onAccepted: settings.preferredLanguage = text
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
