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
# Reject opencv_dart's dependency (no binaries); only use explicit user path.
if(OpenCV_DIR MATCHES "_deps[/\\\\]libopencv")
  message(FATAL_ERROR "Iris Engine: OpenCV_DIR points to opencv_dart's sources (no DLLs). Set OpenCV_DIR to your built OpenCV (e.g. C:/opencv/build).")
endif()

# When OpenCV comes from vcpkg (e.g. .../installed/x64-windows/share/opencv4), its
# config pulls in Protobuf etc. Add the vcpkg triplet dir to CMAKE_PREFIX_PATH so
# find_dependency(Protobuf) inside OpenCVConfig.cmake succeeds.
if(OpenCV_DIR MATCHES "[/\\\\]installed[/\\\\][^/\\\\]+[/\\\\]share[/\\\\]opencv[4]?([/\\\\]|$)")
  get_filename_component(_ocv_abs "${OpenCV_DIR}" REALPATH)
  get_filename_component(_share_dir "${_ocv_abs}" DIRECTORY)    # .../share
  get_filename_component(_vcpkg_triplet "${_share_dir}" DIRECTORY)  # .../x64-windows
  list(PREPEND CMAKE_PREFIX_PATH "${_vcpkg_triplet}")
  set(IRIS_ENGINE_VCPKG_BIN_DIR "${_vcpkg_triplet}/bin" CACHE INTERNAL "vcpkg bin for OpenCV DLLs")
  set(IRIS_ENGINE_OPENCV_DLL_DIR "${_vcpkg_triplet}/bin" CACHE INTERNAL "OpenCV runtime DLL dir for POST_BUILD copy")
  message(STATUS "Iris Engine: Using vcpkg prefix for OpenCV deps: ${_vcpkg_triplet}")
endif()

if(OpenCV_DIR)
  find_package(OpenCV REQUIRED PATHS "${OpenCV_DIR}" NO_DEFAULT_PATH)
else()
  find_package(OpenCV REQUIRED)
endif()

target_include_directories(iris_engine PRIVATE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(iris_engine PRIVATE ${OpenCV_LIBS})

# Non-vcpkg: set OpenCV DLL dir for POST_BUILD copy (opencv_world411.dll etc.)
if(NOT DEFINED IRIS_ENGINE_OPENCV_DLL_DIR)
  set(_opencv_root_guess "${OpenCV_DIR}")
  if(OpenCV_DIR MATCHES "[/\\\\]share[/\\\\]opencv[4]?([/\\\\]|$)")
    get_filename_component(_share_dir "${OpenCV_DIR}" DIRECTORY)    # .../share
    get_filename_component(_opencv_root_guess "${_share_dir}" DIRECTORY)
  elseif(OpenCV_DIR MATCHES "[/\\\\]lib[/\\\\]cmake[/\\\\]opencv[4]?([/\\\\]|$)")
    get_filename_component(_cmake_dir "${OpenCV_DIR}" DIRECTORY)    # .../cmake
    get_filename_component(_lib_dir "${_cmake_dir}" DIRECTORY)      # .../lib
    get_filename_component(_opencv_root_guess "${_lib_dir}" DIRECTORY)
  elseif(OpenCV_DIR MATCHES "[/\\\\]lib[/\\\\]opencv[4]?([/\\\\]|$)")
    get_filename_component(_lib_dir "${OpenCV_DIR}" DIRECTORY)      # .../lib
    get_filename_component(_opencv_root_guess "${_lib_dir}" DIRECTORY)
  endif()

  foreach(_base "${OpenCV_DIR}" "${_opencv_root_guess}")
    if(NOT _base)
      continue()
    endif()
    foreach(_bin "x64/vc16/bin" "bin" "x64/vc15/bin")
      set(_cand "${_base}/${_bin}")
      if(EXISTS "${_cand}")
        file(GLOB _ocvdll "${_cand}/opencv_world*.dll")
        if(_ocvdll)
          set(IRIS_ENGINE_OPENCV_DLL_DIR "${_cand}" CACHE INTERNAL "OpenCV runtime DLL dir for POST_BUILD copy")
          break()
        endif()
      endif()
    endforeach()
    if(DEFINED IRIS_ENGINE_OPENCV_DLL_DIR)
      break()
    endif()
  endforeach()
endif()

if(NOT DEFINED IRIS_ENGINE_OPENCV_DLL_DIR)
  message(FATAL_ERROR "Iris Engine: Could not locate OpenCV DLLs for POST_BUILD copy. Set OpenCV_DIR to your built OpenCV root (e.g. C:/opencv/build) or vcpkg share/opencv4.")
endif()

if(NOT EXISTS "${IRIS_ENGINE_OPENCV_DLL_DIR}")
  message(FATAL_ERROR "Iris Engine: OpenCV DLL dir not found: ${IRIS_ENGINE_OPENCV_DLL_DIR}")
endif()

message(STATUS "Iris Engine: OpenCV required and linked.")

# Windows: avoid min/max macros
target_compile_definitions(iris_engine PRIVATE NOMINMAX)

add_custom_command(TARGET iris_engine POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
  "${IRIS_ENGINE_OPENCV_DLL_DIR}"
  $<TARGET_FILE_DIR:iris_engine>
)

# Warnings (match Flutter runner style if desired)
if(MSVC)
  target_compile_options(iris_engine PRIVATE /W4 /WX-)
else()
  target_compile_options(iris_engine PRIVATE -Wall -Wextra)
endif()
