NULL =
CLEANFILES =
EXTRA_DIST =

# convenience command for doing Makefile variable substitutions in non-Makefile
# files (scripts, service files, etc.)
do_subst = sed  -e 's|@abs_top_srcdir[@]|$(abs_top_srcdir)|g'		\
		-e 's|@abs_top_builddir[@]|$(abs_top_builddir)|g'	\
		-e 's|@localedir[@]|$(localedir)|g'			\
		-e 's|@bindir[@]|$(bindir)|g'				\
		-e 's|@libdir[@]|$(libdir)|g'				\
		-e 's|@libexecdir[@]|$(libexecdir)|g'			\
		-e 's|@pkglibdir[@]|$(pkglibdir)|g'			\
		-e 's|@pkgdatadir[@]|$(pkgdatadir)|g'			\
		-e 's|@GJS_CONSOLE[@]|$(GJS_CONSOLE)|g'			\
		-e 's|@PACKAGE_NAME[@]|$(PACKAGE_NAME)|g'		\
		-e 's|@PACKAGE_VERSION[@]|$(PACKAGE_VERSION)|g'		\
		-e 's|@GETTEXT_PACKAGE[@]|$(GETTEXT_PACKAGE)|g'

js_filesdir = $(pkgdatadir)/js
js_files_DATA = \
	builderInit.js \
	builderAdd.js \
	builderRun.js \
	codeLoader.js \
	codeWriter.js \
	componentLoader.js \
	emulation.js \
	main.js \
	noflo.js \
	options.js \
	path.js \
	runtime.js \
	utils.js \
	websocketServer.js \
	$(NULL)

js_libsdir = $(pkgdatadir)/js/libs
js_libs_DATA = \
	libs/coffeescript.js \
	libs/noflo-runtime-base.js \
	$(NULL)

path.js: path.js.in
	$(AM_V_GEN) $(do_subst) $< > $@

noflo-gnome: noflo-gnome.in
	$(AM_V_GEN) $(do_subst) $< > $@

bin_SCRIPTS = noflo-gnome
CLEANFILES += \
	noflo-gnome \
	path.js \
	$(NULL)
