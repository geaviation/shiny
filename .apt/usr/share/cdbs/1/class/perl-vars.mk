# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Colin Walters <walters@debian.org>
# Copyright © 2003,2008 Jonas Smedegaard <dr@jones.dk>
# Description: Defines useful variables for Perl modules
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

ifndef _cdbs_class_perl_vars
_cdbs_class_perl_vars = 1

include $(_cdbs_rules_path)/buildvars.mk$(_cdbs_makefile_suffix)

DEB_PERL_PACKAGES ?= $(filter lib%-perl, $(DEB_PACKAGES))

DEB_PERL_ARCH_PACKAGES ?= $(filter $(DEB_PERL_PACKAGES), $(DEB_ARCH_PACKAGES))
DEB_PERL_INDEP_PACKAGES ?= $(filter $(DEB_PERL_PACKAGES), $(DEB_INDEP_PACKAGES))

# Use DEB_SRCDIR by default
DEB_PERL_SRCDIR ?= $(DEB_SRCDIR)

# Install directly by default if there is only one perl library package
# To get default CDBS behaviour (CDBS_DESTDIR_pkg or else CDBS_DESTDIR),
# then set DEB_PERL_DESTDIR = $(cdbs_curdestdir)
DEB_PERL_DESTDIR ?= $(if $(filter 1,$(words $(DEB_PERL_PACKAGES))),$(CURDIR)/debian/$(DEB_PERL_PACKAGES),$(cdbs_curdestdir))

# Avoid auto-building dependencies
export PERL_AUTOINSTALL = --skipdeps

endif
