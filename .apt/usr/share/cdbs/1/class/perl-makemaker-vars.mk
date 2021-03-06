# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Colin Walters <walters@debian.org>
# Copyright © 2003,2008-2009 Jonas Smedegaard <dr@jones.dk>
# Description: Defines useful variables for Perl MakeMaker modules
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

# TODO: rewrite to use $(cdbs_make_curdestdir)

_cdbs_scripts_path ?= /usr/lib/cdbs
_cdbs_rules_path ?= /usr/share/cdbs/1/rules
_cdbs_class_path ?= /usr/share/cdbs/1/class

ifndef _cdbs_class_perl_makemaker_vars
_cdbs_class_perl_makemaker_vars = 1

include $(_cdbs_class_path)/perl-vars.mk$(_cdbs_makefile_suffix)
include $(_cdbs_class_path)/makefile-vars.mk$(_cdbs_makefile_suffix)

# Override optimizations to follow Perl Policy 3.9.4 § 4.3
# and extend to also pass CPPFLAGS and LDFLAGS
DEB_MAKE_EXTRA_ARGS ?= OPTIMIZE="$(or $(CFLAGS_$(cdbs_curpkg)),$(CFLAGS)) $(or $(CPPFLAGS_$(cdbs_curpkg)),$(CPPFLAGS))" $(DEB_MAKE_PARALLEL)

DEB_MAKEMAKER_INVOKE ?= /usr/bin/perl Makefile.PL $(DEB_MAKEMAKER_USER_FLAGS) INSTALLDIRS=vendor

# Set some MakeMaker defaults
DEB_MAKE_BUILD_TARGET ?= all
DEB_MAKE_CLEAN_TARGET ?= distclean
DEB_MAKE_CHECK_TARGET ?= test TEST_VERBOSE=1
DEB_MAKE_INSTALL_TARGET ?= install DESTDIR="$(DEB_PERL_DESTDIR)"

endif
