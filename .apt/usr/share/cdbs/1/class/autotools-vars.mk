# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2002,2003 Colin Walters <walters@debian.org>
# Copyright © 2008-2009 Jonas Smedegaard <dr@jones.dk>
# Description: Common variables for GNU autoconf+automake packages
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

_cdbs_scripts_path ?= /usr/lib/cdbs
_cdbs_rules_path ?= /usr/share/cdbs/1/rules
_cdbs_class_path ?= /usr/share/cdbs/1/class

ifndef _cdbs_class_autotools_vars
_cdbs_class_autotools_vars = 1

include $(_cdbs_class_path)/makefile.mk$(_cdbs_makefile_suffix)

DEB_MAKE_INSTALL_TARGET ?= install DESTDIR=$(cdbs_make_curdestdir)
# FIXME: Restructure to allow early override
DEB_MAKE_CLEAN_TARGET = distclean
#DEB_MAKE_CHECK_TARGET = check

DEB_AC_AUX_DIR ?= $(DEB_SRCDIR)

# Declare CC and CXX only if explicitly set in environment or makefile
# (i.e. skip if builtin make default would have been used)
# This is needed for proper cross-compilation - see bug#450483)
DEB_CONFIGURE_SCRIPT_ENV ?= $(call cdbs_set_nondefaultvars,CC CXX) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" CPPFLAGS="$(CPPFLAGS)" LDFLAGS="$(LDFLAGS)"

DEB_CONFIGURE_SCRIPT ?= $(CURDIR)/$(DEB_SRCDIR)/configure

# Provide --host only if different from --build, to support cross-
# compiling with autotools 2.52+ without slowing down normal builds.
# Cross-compiling with autotools 2.13 is unsupported, as it needs
# other tweaks (more info at autotools-dev README.Debian)
DEB_CONFIGURE_CROSSBUILD_ARGS ?= --build=$(DEB_BUILD_GNU_TYPE) $(if $(cdbs_crossbuild),--host=$(DEB_HOST_GNU_TYPE))

DEB_CONFIGURE_PREFIX ?=/usr
DEB_CONFIGURE_INCLUDEDIR ?= "\$${prefix}/include"
DEB_CONFIGURE_MANDIR ?= "\$${prefix}/share/man"
DEB_CONFIGURE_INFODIR ?= "\$${prefix}/share/info"
DEB_CONFIGURE_SYSCONFDIR ?= /etc
DEB_CONFIGURE_LOCALSTATEDIR ?= /var
DEB_CONFIGURE_LIBEXECDIR ?= "\$${prefix}/lib/$(DEB_SOURCE_PACKAGE)"
# --srcdir=. is required because otherwise configure wants to analyse
# $0 to see whether a VPATH build is needed.  This tells it with
# absolute certainly that this is NOT a VPATH build.
DEB_CONFIGURE_PATH_ARGS ?= --prefix=$(DEB_CONFIGURE_PREFIX) --includedir=$(DEB_CONFIGURE_INCLUDEDIR) --mandir=$(DEB_CONFIGURE_MANDIR) --infodir=$(DEB_CONFIGURE_INFODIR) --sysconfdir=$(DEB_CONFIGURE_SYSCONFDIR) --localstatedir=$(DEB_CONFIGURE_LOCALSTATEDIR) --libexecdir=$(DEB_CONFIGURE_LIBEXECDIR) $(if $(subst $(DEB_SRCDIR),,$(cdbs_make_curbuilddir)),,--srcdir=.)

DEB_CONFIGURE_NORMAL_ARGS ?= $(DEB_CONFIGURE_CROSSBUILD_ARGS) $(DEB_CONFIGURE_PATH_ARGS) --disable-maintainer-mode --disable-dependency-tracking --disable-silent-rules

ifneq (,$(filter debug,$(DEB_BUILD_OPTIONS)))
DEB_CONFIGURE_DEBUG_ARGS ?= --enable-debug
endif

DEB_CONFIGURE_INVOKE ?= cd $(cdbs_make_curbuilddir) && $(DEB_CONFIGURE_SCRIPT_ENV) $(DEB_CONFIGURE_SCRIPT) $(DEB_CONFIGURE_NORMAL_ARGS) $(DEB_CONFIGURE_DEBUG_ARGS)

#DEB_CONFIGURE_EXTRA_FLAGS =

CDBS_BUILD_DEPENDS_class_autotools-vars_libtool ?= libtool
CDBS_BUILD_DEPENDS += $(if $(DEB_AUTO_UPDATE_LIBTOOL),$(comma) $(CDBS_BUILD_DEPENDS_class_autotools-vars_libtool))

CDBS_BUILD_DEPENDS_class_autotools-vars_automake ?= automake$(DEB_AUTO_UPDATE_AUTOMAKE)
CDBS_BUILD_DEPENDS += $(if $(DEB_AUTO_UPDATE_AUTOMAKE),$(comma) $(CDBS_BUILD_DEPENDS_class_autotools-vars_automake))

CDBS_BUILD_DEPENDS_class_autotools-vars_aclocal ?= automake$(DEB_AUTO_UPDATE_ACLOCAL)
CDBS_BUILD_DEPENDS += $(if $(DEB_AUTO_UPDATE_ACLOCAL),$(comma) $(CDBS_BUILD_DEPENDS_class_autotools-vars_aclocal))

CDBS_BUILD_DEPENDS_class_autotools-vars_autoconf ?= autoconf$(filter 2.13,$(DEB_AUTO_UPDATE_AUTOCONF))
CDBS_BUILD_DEPENDS += $(if $(DEB_AUTO_UPDATE_AUTOCONF),$(comma) $(CDBS_BUILD_DEPENDS_class_autotools-vars_autoconf))

CDBS_BUILD_DEPENDS_class_autotools-vars_autoheader ?= autoconf$(filter 2.13,$(DEB_AUTO_UPDATE_AUTOHEADER))
CDBS_BUILD_DEPENDS += $(if $(DEB_AUTO_UPDATE_AUTOHEADER),$(comma) $(CDBS_BUILD_DEPENDS_class_autotools-vars_autoheader))

endif
