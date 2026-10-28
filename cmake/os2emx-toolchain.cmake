# CMake toolchain for the OS/2 EMX compiler exported by /data/shell.nix.
# Invoke CMake from `nix-shell /data/shell.nix` so these environment variables
# are available both to the first configure and to CMake's try_compile checks.

foreach(_required OS2EMX_CC OS2EMX_SYSROOT OS2EMX_AR OS2EMX_RANLIB)
  if(NOT DEFINED ENV{${_required}} OR "$ENV{${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} must be set by /data/shell.nix")
  endif()
endforeach()

set(CMAKE_SYSTEM_NAME OS2)
set(CMAKE_SYSTEM_PROCESSOR i686)
set(CMAKE_C_COMPILER "$ENV{OS2EMX_CC}")
set(CMAKE_SYSROOT "$ENV{OS2EMX_SYSROOT}")
set(CMAKE_AR "$ENV{OS2EMX_AR}")
set(CMAKE_RANLIB "$ENV{OS2EMX_RANLIB}" CACHE STRING "No-op ranlib for OMF archives" FORCE)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# CMake's generic archive rules use `q` and then run ranlib. emxomfar requires
# `cr`/`r` and already writes OMF archives; do not run a GNU ranlib on them.
set(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> cr <TARGET> <OBJECTS>")
set(CMAKE_C_ARCHIVE_APPEND "<CMAKE_AR> r <TARGET> <OBJECTS>")
set(CMAKE_C_ARCHIVE_FINISH "<CMAKE_COMMAND> -E true")

set(CMAKE_FIND_ROOT_PATH "${CMAKE_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_C_FLAGS_INIT "-Zomf")
