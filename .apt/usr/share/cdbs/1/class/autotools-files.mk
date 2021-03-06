# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2005 Robert Millan
# Description: A class to automatically update GNU autotools files
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

ifndef _cdbs_class_autotools_files
_cdbs_class_autotools_files = 1

include $(_cdbs_class_path)/autotools-vars.mk$(_cdbs_makefile_suffix)

# Compatibility blurb, will be eventualy removed
ifneq ($(DEB_AUTO_UPDATE_AUTOMAKE), )
ifeq ($(DEB_AUTO_UPDATE_ACLOCAL), )
$(warning WARNING:  DEB_AUTO_UPDATE_AUTOMAKE will eventually stop implying DEB_AUTO_UPDATE_ACLOCAL.  If you meant aclocal.m4 to be regenerated, please use DEB_AUTO_UPDATE_ACLOCAL.)
DEB_AUTO_UPDATE_ACLOCAL ?= $(DEB_AUTO_UPDATE_AUTOMAKE)
endif
endif

# Some update rules are useless on their own
ifeq ($(DEB_AUTO_UPDATE_LIBTOOL), pre)
ifeq ($(DEB_AUTO_UPDATE_ACLOCAL), )
$(warning WARNING:  DEB_AUTO_UPDATE_LIBTOOL requires DEB_AUTO_UPDATE_ACLOCAL.)
endif
endif
ifneq ($(DEB_AUTO_UPDATE_ACLOCAL), )
ifeq ($(DEB_AUTO_UPDATE_AUTOCONF), )
$(warning WARNING:  DEB_AUTO_UPDATE_ACLOCAL requires DEB_AUTO_UPDATE_AUTOCONF.)
endif
endif

DEB_ACLOCAL_ARGS ?= $(if $(wildcard $(DEB_SRCDIR)/m4),-I m4)

common-configure-arch common-configure-indep:: debian/stamp-autotools-files
debian/stamp-autotools-files:
	$(if $(filter pre,$(DEB_AUTO_UPDATE_LIBTOOL)),cd $(DEB_SRCDIR) && libtoolize -c -f)
	$(if $(DEB_AUTO_UPDATE_ACLOCAL),cd $(DEB_SRCDIR) && aclocal-$(DEB_AUTO_UPDATE_ACLOCAL) $(DEB_ACLOCAL_ARGS))
	$(if $(DEB_AUTO_UPDATE_AUTOCONF),if [ -e $(DEB_SRCDIR)/configure.ac ] || [ -e $(DEB_SRCDIR)/configure.in ]; then cd $(DEB_SRCDIR) && `which autoconf$(DEB_AUTO_UPDATE_AUTOCONF) || which autoconf`; fi)
	$(if $(DEB_AUTO_UPDATE_AUTOHEADER),if [ -e $(DEB_SRCDIR)/configure.ac ] || [ -e $(DEB_SRCDIR)/configure.in ]; then cd $(DEB_SRCDIR) && `which autoheader$(DEB_AUTO_UPDATE_AUTOHEADER) || which autoheader` ; fi)
	$(if $(DEB_AUTO_UPDATE_AUTOMAKE),if [ -e $(DEB_SRCDIR)/Makefile.am ]; then cd $(DEB_SRCDIR) && automake-$(DEB_AUTO_UPDATE_AUTOMAKE) $(DEB_AUTOMAKE_ARGS) ; fi)
	touch debian/stamp-autotools-files

clean::
	rm -f debian/stamp-autotools-files

endif
