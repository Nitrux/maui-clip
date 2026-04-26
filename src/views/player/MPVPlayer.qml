import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtMultimedia

import org.mauikit.controls as Maui

import mpv 1.0

MpvObject
{
    id: control
    property alias url : control.source
    property alias video : control
    property alias playerVolume : control.volume
    property int fillMode: VideoOutput.PreserveAspectFit
    readonly property bool supportsFillMode: false
    property bool hasError: false
    property string lastErrorString: ""

    readonly property bool isPlaying : control.playbackState === MediaPlayer.PlayingState
    readonly property bool isPaused : control.playbackState === MediaPlayer.PausedState
    readonly property bool isStopped :  control.playbackState === MediaPlayer.StoppedState

    autoPlay: true
    hardwareDecoding: settings.hardwareDecoding
    onEndOfFile: playNext()
    onError: (message) =>
    {
        hasError = true
        lastErrorString = message
    }
    onFileLoaded:
    {
        hasError = false
        lastErrorString = ""
    }
    onSourceChanged:
    {
        hasError = false
        lastErrorString = ""
    }

    Maui.InfoDialog
    {
        id: _subtitlesDialog
        title: i18n("Subtitles")

        Repeater
        {
            model: control.subtitleTracksModel

            Maui.ListBrowserDelegate
            {
                Layout.fillWidth: true
                label1.text: model.text
                label2.text: model.language
            }
        }
    }

    Maui.InfoDialog
    {
        id: _audioTracksDialog
        title: i18n("Audio Tracks")

        Repeater
        {
            model: control.audioTracksModel

            Maui.ListBrowserDelegate
            {
                Layout.fillWidth: true
                label1.text: model.text
                label2.text: model.language
            }
        }
    }

}

