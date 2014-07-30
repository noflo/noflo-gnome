m4_define([noflo_gnome_major_version], [0])
m4_define([noflo_gnome_minor_version], [1])
m4_define([noflo_gnome_micro_version], [0])
m4_define([noflo_gnome_version],
          [noflo_gnome_major_version.noflo_gnome_minor_version.noflo_gnome_micro_version])

AC_INIT([noflo-gnome],
        [noflo_gnome_version],
        [],
        [noflo-gnome])

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_SRCDIR([src/main.js])

AM_INIT_AUTOMAKE([1.10 no-define foreign dist-xz no-dist-gzip])
AM_MAINTAINER_MODE([enable])

PKG_PROG_PKG_CONFIG([0.22])

GIO_MIN_VERSION=2.38.0
GJS_MIN_VERSION=1.38.0
GOBJECT_INTROSPECTION_MIN_VERSION=0.10.1

PKG_CHECK_MODULES(NOFLO_GNOME, [
    gio-2.0                      >= $GIO_MIN_VERSION
    gjs-1.0                      >= $GJS_MIN_VERSION
    gobject-introspection-1.0    >= $GOBJECT_INTROSPECTION_MIN_VERSION
    libsoup-2.4
])

GLIB_GSETTINGS

GJS_CONSOLE=`$PKG_CONFIG --variable=gjs_console gjs-1.0`
AC_SUBST(GJS_CONSOLE)

AC_CONFIG_FILES([
    Makefile
    components/Makefile
    components/components-base/Makefile
    components/components-clutter/Makefile
    components/components-gir/Makefile
    components/components-gtk/Makefile
    examples/Makefile
    examples/2048/Makefile
    examples/cat/Makefile
    examples/mpris-player/Makefile
    src/Makefile
])
AC_OUTPUT
