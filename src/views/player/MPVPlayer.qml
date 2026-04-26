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
    readonly property bool supportsFillMode: true
    property bool hasError: false
    property string lastErrorString: ""
    readonly property bool hasSubtitleTracks: !!control.subtitleTracksModel && control.subtitleTracksModel.count > 1
    readonly property bool hasAudioTracks: !!control.audioTracksModel && control.audioTracksModel.count > 1

    readonly property bool isPlaying : control.playbackState === MediaPlayer.PlayingState
    readonly property bool isPaused : control.playbackState === MediaPlayer.PausedState
    readonly property bool isStopped :  control.playbackState === MediaPlayer.StoppedState

    Component.onCompleted: applyFillMode()
    autoPlay: true
    hardwareDecoding: settings.hardwareDecoding
    onEndOfFile: playNext()
    onFillModeChanged: applyFillMode()
    onError: (message) =>
    {
        hasError = true
        lastErrorString = message
    }
    onFileLoaded:
    {
        hasError = false
        lastErrorString = ""
        applyFillMode()
    }
    onSourceChanged:
    {
        hasError = false
        lastErrorString = ""
    }

    function applyFillMode()
    {
        control.setProperty("video-unscaled", false)

        switch (fillMode) {
        case VideoOutput.Stretch:
            control.setProperty("keepaspect", false)
            control.setProperty("panscan", 0)
            break
        case VideoOutput.PreserveAspectCrop:
            control.setProperty("keepaspect", true)
            control.setProperty("panscan", 1)
            break
        case VideoOutput.PreserveAspectFit:
        default:
            control.setProperty("keepaspect", true)
            control.setProperty("panscan", 0)
            break
        }
    }

    function openSubtitlesDialog()
    {
        _subtitlesDialog.open()
    }

    function openAudioTracksDialog()
    {
        _audioTracksDialog.open()
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
                checkable: true
                autoExclusive: true
                checked: control.subtitleId === model.id
                onClicked:
                {
                    control.subtitleId = model.id
                    _subtitlesDialog.close()
                }
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
                checkable: true
                autoExclusive: true
                checked: control.audioId === model.id
                onClicked:
                {
                    control.audioId = model.id
                    _audioTracksDialog.close()
                }
            }
        }
    }

}
