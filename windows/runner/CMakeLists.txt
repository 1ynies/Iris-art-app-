cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Ensure iris_engine is built before the app.
add_dependencies(${BINARY_NAME} iris_engine)

# --- POST_BUILD: copy iris_engine.dll and OpenCV runtime DLLs next to the exe ---
# Prefer OpenCV dir from iris_engine, else fall back to project-root .vcpkg.
set(_ocv_srcdir "")
if(DEFINED IRIS_ENGINE_OPENCV_DLL_DIR AND EXISTS "${IRIS_ENGINE_OPENCV_DLL_DIR}")
  set(_ocv_srcdir "${IRIS_ENGINE_OPENCV_DLL_DIR}")
else()
  get_filename_component(_proj_root "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
  set(_vcpkg_bin "${_proj_root}/.vcpkg/installed/x64-windows/bin")
  if(EXISTS "${_vcpkg_bin}")
    set(_ocv_srcdir "${_vcpkg_bin}")
  endif()
endif()

add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    $<TARGET_FILE:iris_engine>
    $<TARGET_FILE_DIR:${BINARY_NAME}>
  COMMENT "Copy iris_engine.dll next to executable for FFI")
if(_ocv_srcdir)
  get_filename_component(_copy_script "${CMAKE_CURRENT_SOURCE_DIR}/copy_vcpkg_dlls.cmake" ABSOLUTE)
  add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND}
      -D "SRCDIR=${_ocv_srcdir}"
      -D "DSTDIR=$<TARGET_FILE_DIR:${BINARY_NAME}>"
      -P "${_copy_script}"
    COMMENT "Copy OpenCV runtime DLLs (opencv_world411.dll etc.) for iris_engine")
endif()
