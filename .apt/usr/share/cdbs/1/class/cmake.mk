# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2006 Peter Rockai <me@mornfall.net>
# Copyright © 2006 Fathi Boudra <fboudra@free.fr>
# Copyright © 2007 Peter Eisentraut <petere@debian.org>
# Description: A class for cmake packages
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

ifndef _cdbs_class_cmake
_cdbs_class_cmake = 1

include $(_cdbs_class_path)/makefile.mk$(_cdbs_makefile_suffix)

# FIXME: Restructure to allow early override (or lowercase the variable!)
ifdef _cdbs_tarball_dir
DEB_BUILDDIR = $(_cdbs_tarball_dir)/obj-$(DEB_BUILD_GNU_TYPE)
else
DEB_BUILDDIR = obj-$(DEB_BUILD_GNU_TYPE)
endif

# Overriden from makefile-vars.mk
# We pass CFLAGS and friends to cmake, so no need to pass them to make
# FIXME: Restructure to allow early override
DEB_MAKE_EXTRA_ARGS = $(DEB_MAKE_PARALLEL)

DEB_MAKE_INSTALL_TARGET ?= install DESTDIR=$(DEB_DESTDIR)

CMAKE ?= cmake
DEB_CMAKE_INSTALL_PREFIX ?= /usr
DEB_CMAKE_CFLAGS ?= $(CFLAGS) $(CPPFLAGS)
DEB_CMAKE_CXXFLAGS ?= $(CXXFLAGS) $(CPPFLAGS)
DEB_CMAKE_LDFLAGS ?= $(LDFLAGS)
DEB_CMAKE_NORMAL_ARGS ?= -DCMAKE_INSTALL_PREFIX="$(DEB_CMAKE_INSTALL_PREFIX)" -DCMAKE_C_COMPILER:FILEPATH="$(CC)" -DCMAKE_CXX_COMPILER:FILEPATH="$(CXX)" -DCMAKE_C_FLAGS="$(DEB_CMAKE_CFLAGS)" -DCMAKE_CXX_FLAGS="$(DEB_CMAKE_CXXFLAGS)" -DCMAKE_SKIP_RPATH=ON -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_EXE_LINKER_FLAGS="$(DEB_CMAKE_LDFLAGS)" -DCMAKE_MODULE_LINKER_FLAGS="$(DEB_CMAKE_LDFLAGS)" -DCMAKE_SHARED_LINKER_FLAGS="$(DEB_CMAKE_LDFLAGS)"

common-configure-arch common-configure-indep:: common-configure-impl
common-configure-impl:: $(DEB_BUILDDIR)/CMakeCache.txt
$(DEB_BUILDDIR)/CMakeCache.txt:
	cd $(DEB_BUILDDIR) && $(CMAKE) $(CURDIR)/$(DEB_SRCDIR) $(DEB_CMAKE_NORMAL_ARGS) $(DEB_CMAKE_EXTRA_FLAGS)

cleanbuilddir::
	-$(if $(call cdbs_streq,$(DEB_BUILDDIR),$(DEB_SRCDIR)),,rm -rf $(DEB_BUILDDIR))

endif
