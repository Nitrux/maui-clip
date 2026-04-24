import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui

import ".."

BrowserLayout
{
    id: control
    objectName: "GalleryView"

    background: null
    Maui.Controls.showCSD: true
    headerMargins: Maui.Style.contentMargins

    holder.emoji: "folder-videos"
    holder.title: i18n("No Videos!")
    holder.body: i18n("Nothing here.")

    onItemClicked: play(item)
}
