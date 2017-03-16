# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Colin Walters <walters@debian.org>
# Copyright © 2003,2009-2010 Jonas Smedegaard <dr@jones.dk>
# Description: Configures, builds, and cleans Perl modules
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

# TODO: rewrite to use $(cdbs_make_curbuilddir)

_cdbs_scripts_path ?= /usr/lib/cdbs
_cdbs_rules_path ?= /usr/share/cdbs/1/rules
_cdbs_class_path ?= /usr/share/cdbs/1/class

ifndef _cdbs_class_perlmodule
_cdbs_class_perlmodule = 1

# Initialize CDBS_BUILD_DEPENDS
include $(_cdbs_rules_path)/buildvars.mk$(_cdbs_makefile_suffix)

$(warning WARNING:  perlmodule.mk is deprecated - please use perl-makemaker.mk instead)

# Dependency according to Perl Policy 3.9.4 § 5.2
CDBS_BUILD_DEPENDS_class_perlmodule ?= perl
CDBS_BUILD_DEPENDS += , $(CDBS_BUILD_DEPENDS_class_perlmodule)

include $(_cdbs_class_path)/perlmodule-vars.mk$(_cdbs_makefile_suffix)

include $(_cdbs_class_path)/makefile.mk$(_cdbs_makefile_suffix)

DEB_MAKEMAKER_PACKAGE ?= tmp

cdbs_makemaker_builddir_check = $(if $(call cdbs_streq,$(DEB_BUILDDIR),$(DEB_SRCDIR)),,$(error DEB_BUILDDIR and DEB_SRCDIR must be the same for Perl builds))

# always be non-interactive
export PERL_MM_USE_DEFAULT = 1

common-configure-arch common-configure-indep:: Makefile
Makefile:
	(cd $(DEB_BUILDDIR) && $(cdbs_makemaker_builddir_check)$(DEB_MAKEMAKER_INVOKE) )

endif
