cmake_minimum_required(VERSION 3.0)

project(twilidoc)

find_package(PkgConfig)
pkg_check_modules(LIBTWILI REQUIRED libtwili>=1.0.0)

file(GLOB_RECURSE twiSrc twilidoc/*.cpp twilidoc/*.hpp)

include_directories(${LIBTWILI_INCLUDE_DIRS})
link_directories(${LIBTWILI_LIBRARY_DIRS})

add_executable(twilidoc ${raritySrc})

target_link_libraries(twilidoc clang twili)
