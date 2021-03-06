# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Colin Walters <walters@debian.org>
# Copyright © 2003,2008 Jonas Smedegaard <dr@jones.dk>
# Description: Defines useful variables for Perl Module::Build modules
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

ifndef _cdbs_class_perl_build_vars
_cdbs_class_perl_build_vars = 1

include $(_cdbs_class_path)/perl-vars.mk$(_cdbs_makefile_suffix)

#DEB_PERL_CONFIGURE_TARGET =
DEB_PERL_CONFIGURE_ARGS ?= --installdirs vendor --config ccflags="$(or $(CFLAGS_$(cdbs_curpkg)),$(CFLAGS))" --config cxxflags="$(or $(CXXFLAGS_$(cdbs_curpkg)),$(CXXFLAGS))" --config cppflags="$(or $(CPPFLAGS_$(cdbs_curpkg)),$(CPPFLAGS))" --config ldflags="$(or $(LDFLAGS_$(cdbs_curpkg)),$(LDFLAGS))"

DEB_PERL_CONFIGURE_FLAGS ?= --destdir $(cdbs_perl_curdestdir)

DEB_PERL_BUILD_TARGET ?= build

# Run tests by default, and loudly
DEB_PERL_CHECK_TARGET ?= test
DEB_PERL_CHECK_FLAGS ?= --verbose 1

DEB_PERL_INSTALL_TARGET ?= install

DEB_PERL_CLEAN_TARGET ?= realclean

endif
