# Copy vcpkg bin/*.dll into DSTDIR. Run with:
#   cmake -D SRCDIR=<vcpkg_installed>/x64-windows/bin -D DSTDIR=<runner_output> -P copy_vcpkg_dlls.cmake
if(NOT SRCDIR OR NOT DSTDIR)
  return()
endif()
if(NOT EXISTS "${SRCDIR}")
  return()
endif()
file(GLOB _dlls "${SRCDIR}/*.dll")
foreach(_d IN LISTS _dlls)
  get_filename_component(_name "${_d}" NAME)
  execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${_d}" "${DSTDIR}/${_name}"
    RESULT_VARIABLE _r)
endforeach()
