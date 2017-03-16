# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2006 Peter Eisentraut <petere@debian.org>
# Description: A class to build qmake packages
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

ifndef _cdbs_class_qmake
_cdbs_class_qmake = 1

include $(_cdbs_class_path)/makefile.mk$(_cdbs_makefile_suffix)

# FIXME: Restructure to allow early override
DEB_MAKE_EXTRA_ARGS = $(DEB_MAKE_PARALLEL)

DEB_MAKE_INSTALL_TARGET = install INSTALL_ROOT=$(DEB_DESTDIR)
DEB_MAKE_CLEAN_TARGET = distclean

QMAKE ?= qmake

ifneq (,$(filter nostrip,$(DEB_BUILD_OPTIONS)))
DEB_QMAKE_CONFIG_VAL ?= nostrip
endif

common-configure-arch common-configure-indep:: common-configure-impl
common-configure-impl:: $(DEB_BUILDDIR)/Makefile
$(DEB_BUILDDIR)/Makefile:
	cd $(DEB_BUILDDIR) && $(QMAKE) $(DEB_QMAKE_ARGS) $(if $(DEB_QMAKE_CONFIG_VAL),'CONFIG += $(DEB_QMAKE_CONFIG_VAL)') 'QMAKE_CC = $(CC)' 'QMAKE_CXX = $(CXX)' 'QMAKE_CFLAGS_RELEASE = $(CPPFLAGS) $(CFLAGS)' 'QMAKE_CXXFLAGS_RELEASE = $(CPPFLAGS) $(CXXFLAGS)' 'QMAKE_LFLAGS_RELEASE = $(LDFLAGS)'

clean::
	rm -f $(DEB_BUILDDIR)/Makefile $(DEB_BUILDDIR)/.qmake.internal.cache

endif
