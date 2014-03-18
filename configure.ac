m4_define([noflo_gnome_major_version], [2])
m4_define([noflo_gnome_minor_version], [30])
m4_define([noflo_gnome_micro_version], [4])
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
])

GLIB_GSETTINGS

AC_CONFIG_FILES([
    Makefile
    src/Makefile
    data/Makefile
])
AC_OUTPUT
