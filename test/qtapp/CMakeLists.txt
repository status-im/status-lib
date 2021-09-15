cmake_minimum_required(VERSION 3.14)

project(test-qtapp LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(ExternalProject)

# QtCreator supports the following variables for Android, which are identical to qmake Android variables.
# Check https://doc.qt.io/qt/deployment-android.html for more information.
# They need to be set before the find_package(...) calls below.

#if(ANDROID)
#    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
#    if (ANDROID_ABI STREQUAL "armeabi-v7a")
#        set(ANDROID_EXTRA_LIBS
#            ${CMAKE_CURRENT_SOURCE_DIR}/path/to/libcrypto.so
#            ${CMAKE_CURRENT_SOURCE_DIR}/path/to/libssl.so)
#    endif()
#endif()

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Quick REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Quick REQUIRED)

set(PROJECT_SOURCES
        nimstatus.cpp
        main.cpp
        qml.qrc
)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(test-qtapp
        ${PROJECT_SOURCES}
    )
else()
    if(ANDROID)
        add_library(test-qtapp SHARED
            ${PROJECT_SOURCES}
        )
    else()
        add_executable(test-qtapp
          ${PROJECT_SOURCES}
        )
    endif()
endif()



# Begin: status-go
set(STATUSGO_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../../vendor/status-go)
set(STATUSGO_LIB_DIR ${STATUSGO_ROOT}/build/bin)
ExternalProject_Add(status-go
  PREFIX ${STATUSGO_ROOT}
  SOURCE_DIR ${STATUSGO_ROOT}
  UPDATE_COMMAND ""
  PATCH_COMMAND ""
  CONFIGURE_COMMAND ""
  INSTALL_COMMAND ""
  BUILD_IN_SOURCE 1
  BUILD_COMMAND make statusgo-shared-library V=1
  BUILD_BYPRODUCTS ${STATUSGO_LIB_DIR}/libstatus.so
)
ExternalProject_Get_Property(status-go SOURCE_DIR)
add_library(status SHARED IMPORTED)
set_property(TARGET status PROPERTY IMPORTED_LOCATION ${STATUSGO_LIB_DIR}/libstatus.so)
add_dependencies(status status-go)
include_directories(${STATUSGO_LIB_DIR})



# Begin: status-lib
set(STATUSLIB_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../..)
set(STATUSLIB_LIB_DIR ${STATUSLIB_ROOT}/build)
ExternalProject_Add(libstatuslib
  PREFIX ${STATUSLIB_ROOT}
  SOURCE_DIR ${STATUSLIB_ROOT}
  UPDATE_COMMAND ""
  PATCH_COMMAND ""
  CONFIGURE_COMMAND ""
  INSTALL_COMMAND ""
  BUILD_IN_SOURCE 1
  BUILD_COMMAND make V=1
  BUILD_BYPRODUCTS ${STATUSLIB_LIB_DIR}/libstatuslib.so
)
ExternalProject_Get_Property(libstatuslib SOURCE_DIR)
add_library(statuslib SHARED IMPORTED)
set_property(TARGET statuslib PROPERTY IMPORTED_LOCATION ${STATUSLIB_LIB_DIR}/libstatuslib.so)
add_dependencies(statuslib libstatuslib)
include_directories(${STATUSLIB_ROOT}/include)



target_compile_definitions(test-qtapp
  PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
target_link_libraries(test-qtapp
  PRIVATE
    Qt${QT_VERSION_MAJOR}::Core
    Qt${QT_VERSION_MAJOR}::Quick
    statuslib  
    status)
