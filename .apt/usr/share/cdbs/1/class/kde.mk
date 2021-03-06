# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Christopher L Cheney <ccheney@debian.org>
# Description: A class for KDE packages; sets KDE environment variables, etc
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

# TODO: rewrite to use $(cdbs_make_curbuilddir) and $(cdbs_make_curdestdir)

_cdbs_scripts_path ?= /usr/lib/cdbs
_cdbs_rules_path ?= /usr/share/cdbs/1/rules
_cdbs_class_path ?= /usr/share/cdbs/1/class

ifndef _cdbs_class_kde
_cdbs_class_kde = 1

include $(_cdbs_rules_path)/buildcore.mk$(_cdbs_makefile_suffix)

# FIXME: Restructure to allow early override
ifdef _cdbs_tarball_dir
DEB_BUILDDIR = $(_cdbs_tarball_dir)/obj-$(DEB_BUILD_GNU_TYPE)
else
DEB_BUILDDIR = obj-$(DEB_BUILD_GNU_TYPE)
endif

include $(_cdbs_class_path)/autotools.mk$(_cdbs_makefile_suffix)

export kde_cgidir  = \$${libdir}/cgi-bin
export kde_confdir = \$${sysconfdir}/kde3
export kde_htmldir = \$${datadir}/doc/kde/HTML

ifeq (,$(filter noopt,$(DEB_BUILD_OPTIONS)))
	cdbs_kde_enable_final = $(if $(DEB_KDE_ENABLE_FINAL),--enable-final,)
endif

ifneq (,$(filter nostrip,$(DEB_BUILD_OPTIONS)))
	cdbs_kde_enable_final =
	cdbs_kde_enable_debug = --enable-debug=yes
else
	cdbs_kde_enable_debug = --disable-debug
endif

ifneq (,$(filter debug,$(DEB_BUILD_OPTIONS)))
	cdbs_kde_enable_debug = --enable-debug=full
endif

cdbs_configure_flags += --with-qt-dir=/usr/share/qt3 --disable-rpath --with-xinerama $(cdbs_kde_enable_final) $(cdbs_kde_enable_debug)

# FIXME: Restructure to allow early override
DEB_AC_AUX_DIR = $(DEB_SRCDIR)/admin
DEB_CONFIGURE_INCLUDEDIR = "\$${prefix}/include/kde"
DEB_COMPRESS_EXCLUDE = .dcl .docbook -license .tag .sty .el

cleanbuilddir::
	-$(if $(call cdbs_streq,$(DEB_BUILDDIR),$(DEB_SRCDIR)),,rm -rf $(DEB_BUILDDIR))

common-build-arch common-build-indep:: debian/stamp-kde-apidox
debian/stamp-kde-apidox:
	$(if $(DEB_KDE_APIDOX),+$(DEB_MAKE_INVOKE) apidox)
	touch $@

common-install-arch common-install-indep:: common-install-kde-apidox
common-install-kde-apidox::
	$(if $(DEB_KDE_APIDOX),+$(DEB_MAKE_INVOKE) install-apidox DESTDIR=$(DEB_DESTDIR))

clean::
	rm -f debian/stamp-kde-apidox

# This is a convenience target for calling manually.  It's not part of
# the build process.
buildprep: clean apply-patches
	$(MAKE) -f admin/Makefile.common dist
	debian/rules clean

endif
