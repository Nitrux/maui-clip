import QtQuick
import QtMultimedia
import QtQuick.Layouts

import QtQuick.Controls

import org.mauikit.controls as Maui
import org.maui.clip as Clip

Clip.Video
{
    id: control
    // source: currentVideo.url
    readonly property alias player : control
    url: currentVideo.url ? currentVideo.url : ""
    property var currentVideo : ({})
    property int currentVideoIndex : -1
}
