import QtMultimedia
import QtQuick

Video
{
    id: control
    readonly property alias video : control
    property alias url : control.source
    property int playerVolume: Math.round(Number(control.volume || 0) * 100)

    readonly property bool isPlaying : control.playbackState === MediaPlayer.PlayingState
    readonly property bool isPaused : control.playbackState === MediaPlayer.PausedState
    readonly property bool isStopped : control.playbackState === MediaPlayer.StoppedState

    // source: currentVideo.url ? currentVideo.url  : undefined
    autoPlay: true
    // seekable: true
    loops: 2
    // focus: true
    endOfStreamPolicy: VideoOutput.KeepLastFrame
    // autoLoad: true
    fillMode: VideoOutput.PreserveAspectFit
    // flushMode: VideoOutput.LastFrame
    // audioRole: MediaPlayer.VideoRole

    onPlayerVolumeChanged:
    {
        const normalizedVolume = Math.max(0, Math.min(100, playerVolume)) / 100

        if (Math.abs(control.volume - normalizedVolume) > 0.001)
            control.volume = normalizedVolume
    }

    onVolumeChanged:
    {
        const normalizedVolume = Math.round(Number(control.volume || 0) * 100)

        if (playerVolume !== normalizedVolume)
            playerVolume = normalizedVolume
    }
}
