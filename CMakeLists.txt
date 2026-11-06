cmake_minimum_required(VERSION 3.10.2)

# uncomment this to force build with gcc instead of clang
#set(CMAKE_C_COMPILER "gcc")

#set(CMAKE_OSX_DEPLOYMENT_TARGET "10.14" CACHE STRING "Minimum OS X deployment version")

project(libvtty C)

# The version is kept in one place, LIBVTTY_VERSION in vtty.h, and read
# from there so the library, its pkg-config file and its packages always
# carry the same major.minor.patch.
file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/vtty.h" _vtty_version_line
    REGEX "^#define[ \t]+LIBVTTY_VERSION[ \t]+\"[0-9]+\\.[0-9]+\\.[0-9]+\"")
string(REGEX REPLACE ".*\"([0-9]+)\\.([0-9]+)\\.([0-9]+)\".*" "\\1;\\2;\\3"
    _vtty_version_parts "${_vtty_version_line}")
list(LENGTH _vtty_version_parts _vtty_version_count)
if(NOT _vtty_version_count EQUAL 3)
    message(FATAL_ERROR "could not read LIBVTTY_VERSION from vtty.h")
endif()
list(GET _vtty_version_parts 0 MAJOR_VERSION)
list(GET _vtty_version_parts 1 MINOR_VERSION)
list(GET _vtty_version_parts 2 PATCH_VERSION)

message("CMAKE_SYSTEM_NAME: ${CMAKE_SYSTEM_NAME}")

option(DEFINE_CURSES "Build with curses" ON)
option(ENABLE_BACKTRACE
    "Install a fatal-signal handler that writes a glibc backtrace to ./vtty-crash-<pid>.log"
    OFF)

# Link-time optimization: lets the compiler inline across translation
# unit boundaries.  libvtty has many small cross-TU helpers
# (vtty_buffer_get_active, clamp_cursor_to_bounds, the VCELL_* shapes)
# that benefit.  Disabled with ENABLE_BACKTRACE since that mode forces
# -O0 for predictable frames.
if(NOT ENABLE_BACKTRACE)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT _libvtty_ipo_ok OUTPUT _libvtty_ipo_err)
    if(_libvtty_ipo_ok)
        message(STATUS "libvtty: link-time optimization ENABLED")
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
    else()
        message(STATUS "libvtty: LTO unavailable: ${_libvtty_ipo_err}")
    endif()
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 -std=c99 -Wall -fPIC -fno-plt")
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -std=c99 -Wall -fPIC -fno-plt")
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 -std=c99 -Wall -fno-omit-frame-pointer -fPIC -fno-plt")
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 -std=c99 -Wall -fsanitize=address -fPIC -fno-plt")
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O1 -std=c99 -Wall -fstack-protector-strong -fPIC -fno-plt")
set(PROJECT_DESCRIPTION "Terminal emulator library for curses programs")

if (("${CMAKE_C_COMPILER_ID}" STREQUAL "Clang") OR (("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU") AND (CMAKE_C_COMPILER_VERSION VERSION_GREATER 6.0)))
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wextra")
endif()

add_definitions("-D_REENTRANT")
add_definitions("-D_POSIX_C_SOURCE=200809L")

# needed for cchar_t definition and turn on "wide support"
add_definitions("-D_XOPEN_SOURCE_EXTENDED")

if ("${CMAKE_SYSTEM_NAME}" STREQUAL "FreeBSD")
    add_definitions("-D__BSD_VISIBLE")
endif()


# set these before running the find_package directive for Curses
set(CURSES_NEED_NCURSES "TRUE")
set(CURSES_NEED_WIDE "TRUE")

if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")

    set(CMAKE_SHARED_LINKER_FLAGS "-Wl,-undefined -Wl,dynamic_lookup")

    set(CMAKE_PREFIX_PATH /usr/local/opt/ncurses)
    include_directories(/usr/local/opt/ncurses/include)

endif() 

if ("${CMAKE_SYSTEM_NAME}" STREQUAL "FreeBSD")

    set(CMAKE_PREFIX_PATH /usr/local/lib)
    include_directories(/usr/local/include)

endif()

find_package(Curses)

add_library(vtty-static STATIC
    color_cache.c
    color_math.c
    glyph_fit.c
    color_map.c
    mouse_driver.c
    mouse_driver_X10.c
    mouse_driver_SGR.c
    nc_wrapper.c
    vtty.c
    vtty_aio.c
    vtty_ctrl_char.c
    vtty_csi.c
    vtty_exec.c
    vtty_erase.c
    vtty_error.c
    vtty_escape.c
    vtty_escape_simple.c
    vtty_escape_suffixes.c
    vtty_buffer.c
    vtty_csi_CBT.c
    vtty_csi_CUP.c
    vtty_csi_CUx.c
    vtty_csi_DCH.c
    vtty_csi_DECSTBM.c
    vtty_csi_DL.c
    vtty_csi_ECH.c
    vtty_csi_ED.c
    vtty_csi_EL.c
    vtty_csi_ICH.c
    vtty_csi_IL.c
    vtty_csi_IRM.c
    vtty_csi_RESTORECUR.c
    vtty_csi_REP.c
    vtty_csi_RS1.c
    vtty_csi_SAVECUR.c
    vtty_csi_SD.c
    vtty_csi_DSR.c
    vtty_csi_SGR.c
    vtty_csi_SU.c
    vtty_csi_UNKNOWN.c
    vtty_cursor.c
    vtty_dec_DECALN.c
    vtty_dec_RM.c
    vtty_dec_SM.c
    vtty_esc_IND.c
    vtty_esc_NEL.c
    vtty_esc_RI.c
    vtty_history.c
    vtty_hook.c
    vtty_osc.c
    vtty_osc_DA.c
    vtty_read.c
    vtty_render.c
    vtty_reply.c
    vtty_resize.c
    vtty_scroll.c
    vtty_userptr.c
    vtty_utf8.c
    vtty_wnd.c
    vtty_write.c
    stringv.c
    )

add_library(vtty.o OBJECT
    color_cache.c
    color_math.c
    glyph_fit.c
    color_map.c
    mouse_driver.c
    mouse_driver_X10.c
    mouse_driver_SGR.c
    nc_wrapper.c
    vtty.c
    vtty_aio.c
    vtty_buffer.c
    vtty_ctrl_char.c
    vtty_csi.c
    vtty_erase.c
    vtty_error.c
    vtty_escape.c
    vtty_escape_simple.c
    vtty_escape_suffixes.c
    vtty_exec.c
    vtty_csi_CBT.c
    vtty_csi_CUP.c
    vtty_csi_CUx.c
    vtty_csi_DCH.c
    vtty_csi_DECSTBM.c
    vtty_csi_DL.c
    vtty_csi_ECH.c
    vtty_csi_ED.c
    vtty_csi_EL.c
    vtty_csi_ICH.c
    vtty_csi_IL.c
    vtty_csi_IRM.c
    vtty_csi_RESTORECUR.c
    vtty_csi_REP.c
    vtty_csi_RS1.c
    vtty_csi_SAVECUR.c
    vtty_csi_SD.c
    vtty_csi_DSR.c
    vtty_csi_SGR.c
    vtty_csi_SU.c
    vtty_csi_UNKNOWN.c
    vtty_cursor.c
    vtty_dec_DECALN.c
    vtty_dec_RM.c
    vtty_dec_SM.c
    vtty_esc_IND.c
    vtty_esc_NEL.c
    vtty_esc_RI.c
    vtty_history.c
    vtty_hook.c
    vtty_osc.c
    vtty_osc_DA.c
    vtty_read.c
    vtty_render.c
    vtty_reply.c
    vtty_resize.c
    vtty_scroll.c
    vtty_userptr.c
    vtty_utf8.c
    vtty_wnd.c
    vtty_write.c
    stringv.c
    )

add_library(vtty-shared SHARED
    $<TARGET_OBJECTS:vtty.o>
    )

#
# Optional backtrace handler.  When ENABLE_BACKTRACE is ON, vtty_debug.c
# is compiled into the regular libvtty.so/.a and its constructor installs
# fatal-signal handlers (SEGV/ABRT/BUS/FPE/ILL).  On signal, a glibc
# backtrace is dumped to ./vtty-crash-<pid>.log in the process's CWD and
# the signal is re-raised under its default disposition so the process
# still terminates (and cores if rlimits allow).
#
# Enable with:    cmake -DENABLE_BACKTRACE=ON  .
# Disable with:   cmake -DENABLE_BACKTRACE=OFF .
#
if(ENABLE_BACKTRACE)
    message(STATUS "libvtty: backtrace handler ENABLED")

    target_sources(vtty-static PRIVATE vtty_debug.c)
    target_sources(vtty.o       PRIVATE vtty_debug.c)

    # -g for line numbers, -O0 for predictable frames,
    # -fno-omit-frame-pointer for reliable unwinding
    target_compile_options(vtty-static PRIVATE
        -g -O0 -fno-omit-frame-pointer)
    target_compile_options(vtty.o PRIVATE
        -g -O0 -fno-omit-frame-pointer)

    target_compile_definitions(vtty-static PRIVATE VTTY_DEBUG_BACKTRACE)
    target_compile_definitions(vtty.o       PRIVATE VTTY_DEBUG_BACKTRACE)

    # -rdynamic exposes symbols so backtrace_symbols_fd() can resolve names
    set_property(TARGET vtty-shared APPEND_STRING
        PROPERTY LINK_FLAGS " -rdynamic")
endif()


# The shared library records the libraries it calls into, so a program
# that links only -lvtty still loads ncurses, libutil and libm with it.
if (("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux") AND (Curses_FOUND))
    target_link_libraries(vtty-shared PRIVATE ${CURSES_LIBRARIES} -lutil -lm)
endif()

if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")

    if (Curses_FOUND)
        if(DEFINE_CURSES)
            add_executable(vshell
                demo/vshell.c
                demo/ctimer.c
                )
        endif(DEFINE_CURSES)
    endif()


    if ((Curses_FOUND) AND (DEFINE_CURSES))
        target_link_libraries(
                    vshell
                    vtty-shared
                    vtty-static
                    -lutil
                    -lm
                    -lrt
                    -ldl
                    ${CURSES_LIBRARIES})
    else()
        target_link_libraries(
                    vtty-shared
                    vtty-static
                    -lutil
                    -lm
                    -lrt
                    -ldl
                    ${CURSES_LIBRARIES})
    endif()
endif()

if ("${CMAKE_SYSTEM_NAME}" STREQUAL "FreeBSD")

    if(DEFINE_CURSES)
        add_executable(vshell
            demo/vshell.c
            demo/ctimer.c
            )
    endif(DEFINE_CURSES)

    if (DEFINE_CURSES)
        target_link_libraries(
                    vshell
                    vtty-shared
                    vtty-static
                    -lc
                    -lutil
                    -lm
                    -lncursesw)
    else()

        target_link_libraries(
                    vtty-shared
                    vtty-static
                    -lc
                    -lutil
                    -lm
                    -lncursesw)
    endif()
endif()

if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")

    if(DEFINE_CURSES)
        add_executable(vshell
            demo/vshell.c
            demo/ctimer.c
            )
    endif(DEFINE_CURSES)

    #link_directories(/usr/local/opt/ncurses/lib/)

    if (DEFINE_CURSES)
        target_link_libraries(
                    vshell
                    vtty-shared
                    vtty-static
                    -lutil
                    -lm
                    /usr/local/opt/ncurses/lib/libncursesw.dylib)
    else()
        target_link_libraries(
                    vtty-shared
                    vtty-static
                    -lutil
                    -lm)
    endif()
endif()


# The static library is built without link-time optimization.  With it,
# the archive holds only GCC's intermediate code, which links with the
# same GCC version and nothing else.  A program that links libvtty.a
# statically still gets ordinary optimized code.
set_property(TARGET vtty-static PROPERTY INTERPROCEDURAL_OPTIMIZATION FALSE)

# CMake doesn't allow targets with the same name.  This renames them properly afterward.
SET_TARGET_PROPERTIES(vtty-static PROPERTIES OUTPUT_NAME vtty CLEAN_DIRECT_OUTPUT 1)
SET_TARGET_PROPERTIES(vtty-shared PROPERTIES OUTPUT_NAME vtty CLEAN_DIRECT_OUTPUT 1)

# The shared library carries a versioned soname (libvtty.so.11) so that a
# program built against one major version is never loaded against another.
SET_TARGET_PROPERTIES(vtty-shared PROPERTIES
    VERSION ${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION}
    SOVERSION ${MAJOR_VERSION})

# set the subst vars that configure_file() will use
set(PROJECT_VERSION ${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION})

# what a program linking the static library needs as well
set(PKG_CONFIG_LIBS_PRIVATE "-lncursesw -lutil -lm")

# @ONLY:  the ${...} in the template are pkg-config's own variables.  the
# prefix is found from where the .pc file sits, so the same file is right
# for /usr/local (make install) and /usr (the packages).
configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/pkg-config.pc.cmake"
  "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pc"
  @ONLY
)

if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")

    if (Curses_FOUND)
        if(DEFINE_CURSES)
            install (TARGETS vshell DESTINATION bin COMPONENT dev)
        endif(DEFINE_CURSES)
    endif()

endif()

if ("${CMAKE_SYSTEM_NAME}" STREQUAL "FreeBSD")

    if(DEFINE_CURSES)
        install (TARGETS vshell DESTINATION bin COMPONENT dev)
    endif(DEFINE_CURSES)

endif()

if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")

    if(DEFINE_CURSES)
        install (TARGETS vshell DESTINATION bin COMPONENT dev)
    endif(DEFINE_CURSES)

endif()

# Every file is given a component, which decides the Debian package it
# goes in:  "runtime" is libvtty11, what a program needs to run, and
# "dev" is libvtty-dev, what is needed to build one.  A plain
# "make install" installs both.
#
# The shared library is installed twice:  its real file and the
# libvtty.so.11 soname link go with the runtime, the bare libvtty.so
# link a linker looks for goes with the development files.
install (TARGETS vtty-shared LIBRARY DESTINATION lib
    COMPONENT runtime NAMELINK_SKIP)
install (TARGETS vtty-shared LIBRARY DESTINATION lib
    COMPONENT dev NAMELINK_ONLY)
install (TARGETS vtty-static ARCHIVE DESTINATION lib COMPONENT dev)
install (FILES vtty.h DESTINATION include COMPONENT dev)

# Debian wants a copyright file (in its machine-readable format) and a
# compressed changelog in each package's own doc directory.  gzip -n
# leaves the time stamp out, so the same source gives the same package.
if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    execute_process(
        COMMAND gzip -9 -n -c "${CMAKE_CURRENT_SOURCE_DIR}/CHANGELOG"
        OUTPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/changelog.gz")

    install (FILES "${CMAKE_CURRENT_SOURCE_DIR}/packaging/copyright"
        "${CMAKE_CURRENT_BINARY_DIR}/changelog.gz"
        DESTINATION share/doc/libvtty${MAJOR_VERSION} COMPONENT runtime)
    install (FILES "${CMAKE_CURRENT_SOURCE_DIR}/packaging/copyright"
        "${CMAKE_CURRENT_BINARY_DIR}/changelog.gz"
        DESTINATION share/doc/libvtty-dev COMPONENT dev)
endif()

# Install pkgconfig files to libdata on BSD, otherwise lib
if(CMAKE_SYSTEM_NAME MATCHES "BSD")
    set(PKG_CONFIG_INSTALL_DIR "libdata/pkgconfig")
else()
    set(PKG_CONFIG_INSTALL_DIR "lib/pkgconfig")
endif()
install (FILES "${PROJECT_BINARY_DIR}/${PROJECT_NAME}.pc"
    DESTINATION ${PKG_CONFIG_INSTALL_DIR} COMPONENT dev)

# Refresh the dynamic linker's cache after installing, so a newly
# installed libvtty.so is found straight away.  Without it a program
# linked against the library fails with "cannot open shared object file"
# until someone runs ldconfig by hand.
#
# Skipped for a staged install (DESTDIR set: a packager installs into a
# scratch root, and the package's own scripts run ldconfig on the real
# system).  Never fatal: an install as a non-root user cannot write the
# cache, and that is reported, not treated as a failed install.
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    install(CODE [[
        if(NOT "$ENV{DESTDIR}" STREQUAL "")
            message(STATUS "DESTDIR is set: not running ldconfig")
        else()
            find_program(VTTY_LDCONFIG ldconfig PATHS /sbin /usr/sbin)
            if(NOT VTTY_LDCONFIG)
                message(STATUS "ldconfig not found: linker cache not refreshed")
            else()
                execute_process(COMMAND "${VTTY_LDCONFIG}"
                    RESULT_VARIABLE vtty_ldconfig_rc
                    OUTPUT_QUIET ERROR_QUIET)
                if(vtty_ldconfig_rc EQUAL 0)
                    message(STATUS "Ran ldconfig")
                else()
                    message(WARNING
                        "ldconfig could not refresh the linker cache "
                        "(not root?).  Run 'sudo ldconfig' before using "
                        "the newly installed library.")
                endif()
            endif()
        endif()
    ]])
endif()

#
# Optional regression harnesses (OFF by default; not installed).
#
#   cmake -DBUILD_TESTS=ON .
#   make
#   ./test_resize          # 8000 deterministic resize/scroll/copy iters
#   ./test_resize <seed>   # alternate size sequence
#   ./test_bufapi          # direct buffer-API: alt-screen clone + dealloc
#
# Built to corner the resize failure mode that sank earlier contiguous-
# buffer attempts.  Run under ASan for full value:
#   cmake -DBUILD_TESTS=ON -DCMAKE_C_FLAGS="-fsanitize=address -g" .
#
option(BUILD_TESTS "Build the libvtty regression test harnesses" OFF)
if(BUILD_TESTS)
    add_executable(test_resize test/test_resize.c)
    add_executable(test_bufapi test/test_bufapi.c)
    add_executable(test_shift test/test_shift.c)
    add_executable(test_history test/test_history.c)
    add_executable(test_render test/test_render.c)
    add_executable(test_osc52 test/test_osc52.c)
    add_executable(test_mouse test/test_mouse.c)
    add_executable(test_osc_title test/test_osc_title.c)
    add_executable(test_color_fit test/test_color_fit.c)
    add_executable(test_glyph_fit test/test_glyph_fit.c)
    foreach(_t test_resize test_bufapi test_shift test_history test_render test_osc52 test_mouse test_osc_title test_color_fit test_glyph_fit)
        target_include_directories(${_t} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
        target_link_libraries(${_t} vtty-static -lncursesw -lutil -lm -lrt)
    endforeach()
endif()

#
# Debian packages:  "make package" builds two .deb files, no root needed.
#
#   libvtty11      the shared library (Section libs)
#   libvtty-dev    header, static library, pkg-config file, the
#                  libvtty.so link and the vshell demo (Section libdevel)
#
# The library's major version is in the runtime package's name, so a new
# major version installs beside the old one instead of replacing it.
# dpkg-shlibdeps works out what each package depends on, and the runtime
# package gets a shlibs file and the ldconfig trigger.
#
# RPM is not built:  an RPM made on a Debian system would put the library
# in lib/ where Fedora expects lib64/.  Build RPMs on an RPM system.
#
set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_NAME "libvtty")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_VERSION_MAJOR "${MAJOR_VERSION}")
set(CPACK_PACKAGE_VERSION_MINOR "${MINOR_VERSION}")
set(CPACK_PACKAGE_VERSION_PATCH "${PATCH_VERSION}")
set(CPACK_PACKAGE_CONTACT "Bryan Christ <bryan.christ@gmail.com>")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/TragicWarrior/libvtty")
set(CPACK_STRIP_FILES ON)

# directories the packages create are 0755, whatever the builder's umask
set(CMAKE_INSTALL_DEFAULT_DIRECTORY_PERMISSIONS
    OWNER_READ OWNER_WRITE OWNER_EXECUTE
    GROUP_READ GROUP_EXECUTE
    WORLD_READ WORLD_EXECUTE)

set(CPACK_DEB_COMPONENT_INSTALL ON)
set(CPACK_COMPONENTS_ALL runtime dev)
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${CPACK_PACKAGE_CONTACT}")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_DEBIAN_PACKAGE_CONTROL_STRICT_PERMISSION ON)

set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS ON)
set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS_POLICY ">=")

# a package description:  the first line is the synopsis, a blank line
# separates paragraphs (CPack writes the " ." Debian wants there).  this
# works because CPACK_PACKAGE_DESCRIPTION_SUMMARY is left unset:  when it
# is set, CPack puts it in front of every package's description.
set(CPACK_DEBIAN_RUNTIME_PACKAGE_NAME "libvtty${MAJOR_VERSION}")
set(CPACK_DEBIAN_RUNTIME_PACKAGE_SECTION "libs")

# the linker cache is refreshed by a dpkg trigger, as Debian asks
set(CPACK_DEBIAN_RUNTIME_PACKAGE_CONTROL_EXTRA
    "${CMAKE_CURRENT_SOURCE_DIR}/packaging/triggers")
set(CPACK_DEBIAN_RUNTIME_DESCRIPTION
"terminal emulator library for curses programs
libvtty runs a program in a pseudo-terminal and keeps what it draws in
an off-screen buffer that a host program renders into a curses window.
It emulates the VT100, rxvt, xterm, xterm-256color and Linux console
terminals, with 24-bit color, mouse reporting, scrollback and window
titles.

This package holds the shared library.  It was named libvterm until
version 11.")

set(CPACK_DEBIAN_DEV_PACKAGE_NAME "libvtty-dev")
set(CPACK_DEBIAN_DEV_PACKAGE_SECTION "libdevel")
set(CPACK_DEBIAN_DEV_PACKAGE_DEPENDS
    "libvtty${MAJOR_VERSION} (= ${PROJECT_VERSION}), libncurses-dev")
set(CPACK_DEBIAN_DEV_DESCRIPTION
"terminal emulator library for curses programs - development files
libvtty runs a program in a pseudo-terminal and keeps what it draws in
an off-screen buffer that a host program renders into a curses window.

This package holds the header, the static library, the pkg-config file
and vshell, a small tmux-like program that demonstrates the library.")

include(CPack)
