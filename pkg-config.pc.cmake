prefix=${pcfiledir}/../..
libdir=${prefix}/lib
includedir=${prefix}/include

Name: @PROJECT_NAME@
Description: @PROJECT_DESCRIPTION@
Version: @PROJECT_VERSION@
URL: https://github.com/TragicWarrior/libvtty
Libs: -L${libdir} -lvtty
Libs.private: @PKG_CONFIG_LIBS_PRIVATE@
Cflags: -I${includedir}
