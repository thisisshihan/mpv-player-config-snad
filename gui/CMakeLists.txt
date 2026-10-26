cmake_minimum_required(VERSION 3.21)
project(mpv-snad-gui LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets OpenGLWidgets)

# MPV_ROOT: folder holding include/mpv/*.h plus the import library and libmpv-2.dll
set(MPV_ROOT "" CACHE PATH "libmpv dev package root")
find_library(MPV_LIB NAMES mpv libmpv mpv-2 PATHS ${MPV_ROOT} NO_DEFAULT_PATH REQUIRED)

add_executable(mpv-snad WIN32
    src/main.cpp
    src/MpvWidget.cpp
    src/MainWindow.cpp
    src/SettingsDialog.cpp
    src/SkinManager.cpp)
target_include_directories(mpv-snad PRIVATE ${MPV_ROOT}/include)
target_link_libraries(mpv-snad PRIVATE Qt6::Widgets Qt6::OpenGLWidgets ${MPV_LIB})

# Repo root (parent of gui/) is the single source of truth for the player config.
set(REPO_ROOT ${CMAKE_SOURCE_DIR}/..)
set(PC $<TARGET_FILE_DIR:mpv-snad>/portable_config)
add_custom_command(TARGET mpv-snad POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${PC}
    COMMAND ${CMAKE_COMMAND} -E copy ${REPO_ROOT}/mpv.conf ${REPO_ROOT}/input.conf ${PC}
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${REPO_ROOT}/scripts ${PC}/scripts
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${REPO_ROOT}/script-opts ${PC}/script-opts
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${REPO_ROOT}/shaders ${PC}/shaders
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${REPO_ROOT}/fonts ${PC}/fonts
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/skins ${PC}/skins)
