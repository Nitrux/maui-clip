project('clip', 'cpp', version: '4.0.5', meson_version: '>=1.0.0', default_options: ['cpp_std=c++17', 'buildtype=release'])
qt6 = import('qt6')
cpp_compiler = meson.get_compiler('cpp')
if cpp_compiler.get_id() == 'gcc' and cpp_compiler.has_argument('-Wno-sfinae-incomplete')
    add_project_arguments('-Wno-sfinae-incomplete', language: 'cpp')
endif
qt = dependency('qt6', version: '>=6.9', modules: ['Core', 'Network', 'Qml', 'Quick', 'Multimedia'])
kf6_core = dependency('KF6CoreAddons', version: '>=6.13')
kf6_i18n = declare_dependency(
    include_directories: include_directories(get_option('prefix') / 'include' / 'KF6' / 'KI18n'),
    dependencies: [cpp_compiler.find_library('KF6I18n'), cpp_compiler.find_library('KF6I18nQml')],
)
mauikit = dependency('MauiKit4', version: '>=4.0.5')
filebrowsing = dependency('MauiKitFileBrowsing4', version: '>=4.0.5')
mpv = dependency('mpv', required: true)
ffmpeg = dependency('libavcodec', required: true)
ffmpeg_filter = dependency('libavfilter', required: true)
ffmpeg_format = dependency('libavformat', required: true)
ffmpeg_util = dependency('libavutil', required: true)
ffmpeg_scale = dependency('libswscale', required: true)
taglib = dependency('taglib', version: '>=1.4', required: true)
cpp_args = ['-D__STDC_CONSTANT_MACROS', '-fexceptions', '-DCLIP_BUILD_BUNDLED_PREVIEW_PROVIDER']
if host_machine.cpu_family() == 'x86_64'
    cpp_args += ['-march=x86-64-v3', '-mtune=generic']
endif
clip_version = configure_file(
    input: 'meson-content.in',
    output: 'clip_version.h',
    configuration: {'CONTENT': ('''#pragma once
#define CLIP_VERSION_STRING "4.0.5"
#define GIT_BRANCH "Stable"
#define GIT_COMMIT_HASH "4.0.5"
''')}
)
clip_includes = include_directories('src')
qt_sources = qt6.preprocess(qresources: ['src/assets.qrc', 'src/qml.qrc'], moc_headers: ['src/backends/mpv/mpvobject.h', 'src/backends/mpv/track.h', 'src/backends/mpv/tracksmodel.h', 'src/backends/mpv/subtitlesfoldersmodel.h', 'src/models/videosmodel.h', 'src/models/tagsmodel.h', 'src/utils/clip.h', 'src/utils/thumbnailer.h'])
clip_sources = ['src/main.cpp', 'src/models/videosmodel.cpp', 'src/models/tagsmodel.cpp', 'src/utils/clip.cpp', 'src/utils/thumbnailer.cpp', 'src/utils/ffmpegthumbs/filmstripfilter.cpp', 'src/utils/ffmpegthumbs/moviedecoder.cpp', 'src/utils/ffmpegthumbs/imagewriter.cpp', 'src/utils/ffmpegthumbs/videothumbnailer.cpp', 'src/backends/mpv/mpvobject.cpp', 'src/backends/mpv/track.cpp', 'src/backends/mpv/tracksmodel.cpp', 'src/backends/mpv/subtitlesfoldersmodel.cpp']
executable('clip', clip_sources + qt_sources + [clip_version], dependencies: [qt, kf6_core, kf6_i18n, mauikit, filebrowsing, mpv, ffmpeg, ffmpeg_filter, ffmpeg_format, ffmpeg_util, ffmpeg_scale, taglib], include_directories: clip_includes, cpp_args: cpp_args, install: true)
install_data('src/org.maui.clip.desktop', install_dir: get_option('datadir') / 'applications')
install_data('src/assets/maui-clip.svg', install_dir: get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps')
