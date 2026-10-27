cmake_minimum_required(VERSION 3.16)
project(libb2 VERSION 0.98.1 LANGUAGES C)

if(CMAKE_SYSTEM_NAME STREQUAL "OS2" AND CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(_libb2_default_install_prefix "/data/os2emx")
  if(DEFINED ENV{OS2EMX_PREFIX} AND NOT "$ENV{OS2EMX_PREFIX}" STREQUAL "")
    set(_libb2_default_install_prefix "$ENV{OS2EMX_PREFIX}")
  endif()
  set(CMAKE_INSTALL_PREFIX "${_libb2_default_install_prefix}" CACHE PATH
    "Default OS/2 installation prefix" FORCE
  )
endif()

include(GNUInstallDirs)
include(CheckSymbolExists)
include(CTest)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)

# Match the portable Autotools implementation. In particular, cross builds do
# not inherit the build host's -march=native or runtime SIMD dispatch choices.
check_symbol_exists(explicit_bzero "string.h" HAVE_EXPLICIT_BZERO)
check_symbol_exists(explicit_memset "string.h" HAVE_EXPLICIT_MEMSET)
check_symbol_exists(memset_s "string.h" HAVE_MEMSET_S)

if(CMAKE_SYSTEM_NAME STREQUAL "OS2")
  # OS/2's configured target here is i686, which is little-endian.
  set(NATIVE_LITTLE_ENDIAN 1)
else()
  include(TestBigEndian)
  test_big_endian(LIBB2_BIG_ENDIAN)
  if(NOT LIBB2_BIG_ENDIAN)
    set(NATIVE_LITTLE_ENDIAN 1)
  endif()
endif()

file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/src")
configure_file(cmake/config.h.in "${CMAKE_CURRENT_BINARY_DIR}/src/config.h")

add_library(b2
  src/blake2b-ref.c
  src/blake2s-ref.c
  src/blake2bp.c
  src/blake2sp.c
)
add_library(libb2::b2 ALIAS b2)

target_compile_definitions(b2 PRIVATE SUFFIX=)
target_include_directories(b2
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  PRIVATE
    "${CMAKE_CURRENT_BINARY_DIR}/src"
)
set_target_properties(b2 PROPERTIES
  OUTPUT_NAME b2
  PUBLIC_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/src/blake2.h"
)

option(LIBB2_ENABLE_OPENMP "Parallelize BLAKE2bp/BLAKE2sp when OpenMP is available" OFF)
if(LIBB2_ENABLE_OPENMP)
  find_package(OpenMP REQUIRED COMPONENTS C)
  target_link_libraries(b2 PRIVATE OpenMP::OpenMP_C)
endif()

if(BUILD_SHARED_LIBS)
  target_compile_definitions(b2 PRIVATE BLAKE2_DLL BLAKE2_DLL_EXPORTS)
  target_compile_definitions(b2 INTERFACE BLAKE2_DLL)
endif()

if(BUILD_TESTING)
  foreach(_algorithm IN ITEMS blake2s blake2b blake2sp blake2bp)
    add_executable(${_algorithm}-test "src/${_algorithm}-test.c")
    target_link_libraries(${_algorithm}-test PRIVATE b2)
    add_test(NAME ${_algorithm} COMMAND ${_algorithm}-test)
  endforeach()
endif()

install(TARGETS b2
  ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
  PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

if(BUILD_SHARED_LIBS)
  set(LIBB2_PC_CFLAGS "-DBLAKE2_DLL")
else()
  set(LIBB2_PC_CFLAGS "")
endif()
configure_file(cmake/libb2.pc.in "${CMAKE_CURRENT_BINARY_DIR}/libb2.pc" @ONLY)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/libb2.pc"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig"
)

if(CMAKE_SYSTEM_NAME STREQUAL "OS2")
  set(LIBB2_TARGET_OS2 "yes")
else()
  set(LIBB2_TARGET_OS2 "no")
endif()
message(STATUS "libb2 ${PROJECT_VERSION}: OS/2=${LIBB2_TARGET_OS2}; tests=${BUILD_TESTING}; OpenMP=${LIBB2_ENABLE_OPENMP}")