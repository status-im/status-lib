cmake_minimum_required(VERSION 3.14)
project(status-lib)

SET(LIB_SHARED_FILE ${CMAKE_CURRENT_SOURCE_DIR}/build/libstatuslib${CMAKE_SHARED_LIBRARY_SUFFIX})
SET(LIB_HEADER_FOLDER ${CMAKE_CURRENT_SOURCE_DIR}/include/)

add_custom_command(OUTPUT  ${LIB_SHARED_FILE}
                   COMMAND make
                   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

add_custom_target(statuslib_target DEPENDS ${LIB_SHARED_FILE})

add_library(statuslib SHARED IMPORTED GLOBAL)

add_dependencies(statuslib statuslib_target)

set_target_properties(statuslib
    PROPERTIES
    IMPORTED_LOCATION ${LIB_SHARED_FILE}
    INTERFACE_INCLUDE_DIRECTORIES ${LIB_HEADER_FOLDER})
