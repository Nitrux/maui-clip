remove_definitions(-DQT_NO_CAST_FROM_ASCII -DQT_STRICT_ITERATORS -DQT_NO_CAST_FROM_BYTEARRAY -DQT_NO_URL_CAST_FROM_STRING)

set(mpvSRCS
    backends/mpv/mpvobject.cpp
    backends/mpv/track.cpp
    backends/mpv/tracksmodel.cpp
    backends/mpv/subtitlesfoldersmodel.cpp
    backends/mpv/qthelper.h)

set(clipSRCS
    main.cpp
    models/videosmodel.cpp
    models/tagsmodel.cpp
    utils/clip.cpp
)

set(clip_ASSETS
    assets.qrc)

if(CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER)
    include_directories(
        ${FFMPEG_INCLUDE_DIRS})

    set(thumbnailerSRCS
        utils/thumbnailer.cpp
        utils/ffmpegthumbs/filmstripfilter.cpp
        utils/ffmpegthumbs/moviedecoder.cpp
        utils/ffmpegthumbs/imagewriter.cpp
        utils/ffmpegthumbs/videothumbnailer.cpp)
endif()

qt_add_executable(${PROJECT_NAME}
    MANUAL_FINALIZATION
    ${clipSRCS}
    ${clip_ASSETS}
    ${thumbnailerSRCS}
    ${mpvSRCS})

qt_add_qml_module(${PROJECT_NAME} URI app.maui.clip
    NO_PLUGIN
    RESOURCE_PREFIX /
    NO_IMPORT_SCAN
    QML_FILES
    main.qml
    views/player/PlayerView.qml
    views/player/MPVPlayer.qml
    views/collection/CollectionView.qml
    views/collection/CollectionsView.qml
    views/tags/TagsView.qml
    views/player/Playlist.qml
    views/tags/TagsGrid.qml
    views/BrowserLayout.qml
    views/ItemMenu.qml
    views/ListDelegate.qml
    views/settings/SettingsDialog.qml
    views/player/Player.qml)

target_compile_definitions(${PROJECT_NAME}
    PRIVATE
    $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
    $<$<BOOL:${CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER}>:CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER>)

target_compile_options(${PROJECT_NAME} PRIVATE -fexceptions ${CLIP_ARCH_OPTIMIZATION_FLAGS})

target_link_libraries(${PROJECT_NAME}
    PRIVATE
    PkgConfig::MPV
    MauiKit4
    MauiKit4::FileBrowsing
    Qt6::Network
    Qt6::Core
    Qt6::Quick
    Qt6::Qml
    Qt6::Multimedia
    KF6::CoreAddons
    KF6::I18n)

if(CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER)
    target_link_libraries(${PROJECT_NAME}
        PRIVATE
        Taglib::Taglib
        ${AVUTIL_LIBRARIES}
        ${AVFILTER_LIBRARIES}
        ${AVFORMAT_LIBRARIES}
        ${AVCODEC_LIBRARIES}
        ${SWSCALE_LIBRARIES})
endif()

install(TARGETS ${PROJECT_NAME} ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(FILES org.kde.clip.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES assets/maui-clip.svg DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps)

qt_finalize_target(${PROJECT_NAME})
