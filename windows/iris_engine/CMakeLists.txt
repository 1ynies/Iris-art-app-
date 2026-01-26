# Iris Engine — Native C++ DLL for image processing (2026)
# Circling requires OpenCV (Hough circles). Set OpenCV_DIR if not in default path.
# Example: cmake -DOpenCV_DIR=C:/opencv/build ...

cmake_minimum_required(VERSION 3.14)
project(iris_engine LANGUAGES CXX)

set(IRIS_ENGINE_SOURCES
  iris_engine.cpp
  iris_engine_ffi.cpp
  iris_cut.cpp
)

add_library(iris_engine SHARED ${IRIS_ENGINE_SOURCES})
target_include_directories(iris_engine PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# C++20 for 2026 backend
target_compile_features(iris_engine PUBLIC cxx_std_20)

# Export FFI symbols on Windows
target_compile_definitions(iris_engine PRIVATE IRIS_ENGINE_DLL_EXPORT)

# OpenCV for circling (Hough) and Phase 1 cut-and-warp.
# Use only when OpenCV_DIR is set to a *built* OpenCV (e.g. C:/opencv/build).
# Do NOT use the opencv_dart plugin's _deps/libopencv-src — it has no compatible binaries.
set(OpenCV_DIR "" CACHE PATH "OpenCV build dir (e.g. C:/opencv/build)")
if(DEFINED ENV{OpenCV_DIR} AND NOT OpenCV_DIR)
  set(OpenCV_DIR "$ENV{OpenCV_DIR}" CACHE PATH "OpenCV build dir (from env)" FORCE)
endif()
# Ignore OpenCV from opencv_dart's dependency (no binaries); only use explicit user path.
if(OpenCV_DIR AND NOT OpenCV_DIR MATCHES "_deps[/\\\\]libopencv")
  # When OpenCV comes from vcpkg (e.g. .../installed/x64-windows/share/opencv4), its
  # config pulls in Protobuf etc. Add the vcpkg triplet dir to CMAKE_PREFIX_PATH so
  # find_dependency(Protobuf) inside OpenCVConfig.cmake succeeds.
  if(OpenCV_DIR MATCHES "[/\\\\]installed[/\\\\][^/\\\\]+[/\\\\]share[/\\\\]opencv[4]?([/\\\\]|$)")
    get_filename_component(_ocv_abs "${OpenCV_DIR}" REALPATH)
    get_filename_component(_share_dir "${_ocv_abs}" DIRECTORY)    # .../share
    get_filename_component(_vcpkg_triplet "${_share_dir}" DIRECTORY)  # .../x64-windows
    list(PREPEND CMAKE_PREFIX_PATH "${_vcpkg_triplet}")
    set(IRIS_ENGINE_VCPKG_BIN_DIR "${_vcpkg_triplet}/bin" CACHE INTERNAL "vcpkg bin for OpenCV DLLs")
    message(STATUS "Iris Engine: Using vcpkg prefix for OpenCV deps: ${_vcpkg_triplet}")
  endif()
  find_package(OpenCV REQUIRED PATHS "${OpenCV_DIR}" NO_DEFAULT_PATH)
else()
  set(OpenCV_FOUND FALSE)
  if(OpenCV_DIR)
    message(WARNING "Iris Engine: Skipping opencv_dart's OpenCV (no compatible binaries). Set OpenCV_DIR to your own OpenCV build (e.g. C:/opencv/build).")
  endif()
endif()
if(OpenCV_FOUND)
  target_include_directories(iris_engine PRIVATE ${OpenCV_INCLUDE_DIRS})
  target_link_libraries(iris_engine PRIVATE ${OpenCV_LIBS})
  target_compile_definitions(iris_engine PRIVATE IRIS_ENGINE_OPENCV_AVAILABLE)
  message(STATUS "Iris Engine: OpenCV found — circling will use Hough")
else()
  message(STATUS "Iris Engine: OpenCV not used. Circling/Phase1 need OpenCV; set OpenCV_DIR to your build (e.g. C:/opencv/build) to enable.")
endif()

# Windows: avoid min/max macros
target_compile_definitions(iris_engine PRIVATE NOMINMAX)

# Warnings (match Flutter runner style if desired)
if(MSVC)
  target_compile_options(iris_engine PRIVATE /W4 /WX-)
else()
  target_compile_options(iris_engine PRIVATE -Wall -Wextra)
endif()
