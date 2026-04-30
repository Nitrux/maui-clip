import QtQuick.Controls

import org.mauikit.controls as Maui

Maui.SettingsDialog
{
    id: control

    Maui.Controls.title: i18n("Shortcuts")

    Maui.SectionGroup
    {
        title: i18n("Library")
        description: i18n("Global shortcuts for opening media and switching between Clip sections.")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Open Files")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "O" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Open URL")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "Shift" }
                Action { text: "O" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Collections")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "1" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Tags")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "2" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Playlist")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "3" }
            }
        }

    }

    Maui.SectionGroup
    {
        title: i18n("Playback")
        description: i18n("Shortcuts available while the player view has focus.")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Play or Pause")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Space" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Seek Backward 5 Seconds")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Left" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Seek Forward 5 Seconds")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Right" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Seek Backward 10 Seconds")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "J" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Seek Forward 10 Seconds")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "L" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Volume Up")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Up" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Volume Down")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Down" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Mute")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "M" }
            }
        }

    }

    Maui.SectionGroup
    {
        title: i18n("General")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Show Shortcuts")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Ctrl" }
                Action { text: "/" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Toggle Full Screen")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "F11" }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Close Sidebar or Exit Full Screen")

            Maui.ToolActions
            {
                checkable: false
                autoExclusive: false

                Action { text: "Esc" }
            }
        }
    }
}
