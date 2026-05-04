# Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
# Copyright 2018-2020 Nitrux Latinoamericana S.C.
#
# SPDX-License-Identifier: GPL-3.0-or-later

cmake_minimum_required(VERSION 3.16)

set(CLIP_VERSION 4.0.2)
add_compile_definitions(APP_COPYRIGHT_NOTICE="© 2019-2025 Maui Development Team")

project(clip VERSION ${CLIP_VERSION} LANGUAGES CXX)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message(FATAL_ERROR "This project supports Linux only.")
endif()


set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(QT_MAJOR_VERSION 6)
set(REQUIRED_QT_VERSION 6.5.2)

set(REQUIRED_KF_VERSION 5.240.0)

# Certain versions of FFMPEG need this to be defined
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D __STDC_CONSTANT_MACROS")

find_package(ECM ${REQUIRED_KF_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(CheckCXXCompilerFlag)

find_package(Qt6 ${REQUIRED_QT_VERSION} REQUIRED NO_MODULE COMPONENTS Core Sql Qml Quick Multimedia Network)
find_package(KF6 ${REQUIRED_KF_VERSION} REQUIRED COMPONENTS I18n CoreAddons)
find_package(MauiKit4 REQUIRED COMPONENTS FileBrowsing)
find_package(PkgConfig REQUIRED)
pkg_check_modules(MPV REQUIRED IMPORTED_TARGET mpv)

set(CLIP_ARCH_OPTIMIZATION_FLAGS "")

if(NOT CMAKE_CROSSCOMPILING AND CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "^(x86_64|X86_64|amd64|AMD64)$")
    check_cxx_compiler_flag("-march=x86-64-v3" CLIP_COMPILER_SUPPORTS_X86_64_V3)

    if(CLIP_COMPILER_SUPPORTS_X86_64_V3)
        list(APPEND CLIP_ARCH_OPTIMIZATION_FLAGS -march=x86-64-v3)

        check_cxx_compiler_flag("-mtune=generic" CLIP_COMPILER_SUPPORTS_MTUNE_GENERIC)
        if(CLIP_COMPILER_SUPPORTS_MTUNE_GENERIC)
            list(APPEND CLIP_ARCH_OPTIMIZATION_FLAGS -mtune=generic)
        endif()

        message(STATUS "Enabling x86-64-v3 optimizations for Clip on native x86_64 builds")
    endif()
endif()

include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDEClangFormat)
include(ECMSetupVersion)
include(ECMSourceVersionControl)
include(FeatureSummary)

option(CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER "Build Clip's bundled FFmpeg/TagLib preview provider" OFF)

if(CLIP_BUILD_BUNDLED_PREVIEW_PROVIDER)
    find_package(FFmpeg COMPONENTS REQUIRED AVCODEC AVFILTER AVFORMAT AVUTIL SWSCALE)
    find_package(Taglib 1.4 REQUIRED)
endif()

if(${ECM_SOURCE_UNDER_VERSION_CONTROL})
    execute_process(
        COMMAND git rev-parse --abbrev-ref HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_BRANCH
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    execute_process(
        COMMAND git log -1 --format=%h
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COMMIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    add_definitions(-DGIT_COMMIT_HASH="${GIT_COMMIT_HASH}")
    add_definitions(-DGIT_BRANCH="${GIT_BRANCH}")
else()
    add_definitions(-DGIT_COMMIT_HASH="${CLIP_VERSION}")
    add_definitions(-DGIT_BRANCH="Stable")
endif()

ecm_setup_version(${CLIP_VERSION}
    VARIABLE_PREFIX CLIP
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/clip_version.h")

qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

add_subdirectory(src)

ki18n_install(po)
install(FILES org.maui.clip.appdata.xml DESTINATION ${KDE_INSTALL_METAINFODIR})

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)

file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES *.cpp *.h)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})

qt_finalize_project()

if(NOT TARGET uninstall)
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
        "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
        IMMEDIATE
        @ONLY)

    add_custom_target(uninstall
        COMMAND ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")
endif()
