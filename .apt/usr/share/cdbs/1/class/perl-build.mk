# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Colin Walters <walters@debian.org>
# Copyright © 2003,2008,2010 Jonas Smedegaard <dr@jones.dk>
# Description: Configures, builds, and cleans Perl Module::Build modules
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

ifndef _cdbs_class_perl_build
_cdbs_class_perl_build = 1

# Initialize CDBS_BUILD_DEPENDS and shared DEB_PERL_*
include $(_cdbs_class_path)/perl-build-vars.mk$(_cdbs_makefile_suffix)
include $(_cdbs_rules_path)/buildcore.mk$(_cdbs_makefile_suffix)

# Dependency according to Perl Policy 3.9.4 § 5.2
CDBS_BUILD_DEPENDS_class_perl-build_perl ?= perl
CDBS_BUILD_DEPENDS += , $(CDBS_BUILD_DEPENDS_class_perl-build_perl)

# Added dependencies when using Module::Build::Tiny
cdbs_perl_module-build-tiny_check := $(shell grep -slP '^use\s+Module::Build::Tiny' $(DEB_PERL_SRCDIR)/Build.PL)
CDBS_BUILD_DEPENDS_class_perl-build_module-build-tiny ?= libmodule-build-tiny-perl, cdbs (>= 0.4.122~)
CDBS_BUILD_DEPENDS += $(if $(cdbs_perl_module-build-tiny_check),$(comma) $(CDBS_BUILD_DEPENDS_class_perl-build_module-build-tiny))

# Sanity check: DEB_PERL_SRCDIR must be declared early
cdbs_perl_srcdir_early := $(DEB_PERL_SRCDIR)
cdbs_perl_srcdir_check = $(if $(call cdbs_streq,$(cdbs_perl_srcdir_early),$(DEB_PERL_SRCDIR)),,$(error DEB_PERL_SRCDIR must be set before including perl-build.mk, not after))

# Sanity check: only DEB_PERL_SRCDIR == DEB_BUILDDIR is supported
# TODO: figure out if Module::Build supports custom builddir
cdbs_perl_builddir_check = $(if $(call cdbs_streq,$(DEB_PERL_SRCDIR),$(DEB_BUILDDIR)),,$(error DEB_PERL_SRCDIR and DEB_BUILDDIR must be the same for Perl Module::Build builds))

cdbs_perl_curbuilddir = $(cdbs_perl_builddir_check)$(cdbs_curbuilddir)
cdbs_perl_curdestdir = $(cdbs_perl_builddir_check)$(or $(DEB_PERL_DESTDIR_$(cdbs_curpkg)),$(DEB_PERL_DESTDIR))

common-configure-arch common-configure-indep:: $(DEB_PERL_SRCDIR)/Build
$(DEB_PERL_SRCDIR)/Build:
	$(cdbs_perl_srcdir_check)
	cd $(cdbs_perl_curbuilddir) && perl Build.PL $(DEB_PERL_BUILD_CONFIGURE_TARGET) $(DEB_PERL_CONFIGURE_ARGS) $(DEB_PERL_CONFIGURE_FLAGS)

common-build-arch common-build-indep:: debian/stamp-perl-build
debian/stamp-perl-build:
	cd $(cdbs_perl_curbuilddir) && ./Build $(DEB_PERL_BUILD_TARGET) $(DEB_PERL_BUILD_ARGS) $(DEB_PERL_BUILD_FLAGS)
	touch $@

common-build-arch common-build-indep:: debian/stamp-perl-check
debian/stamp-perl-check: debian/stamp-perl-build
	$(if $(filter nocheck,$(DEB_BUILD_OPTIONS)),,$(if $(DEB_PERL_CHECK_TARGET),cd $(cdbs_perl_curbuilddir) && ./Build $(DEB_PERL_CHECK_TARGET) $(DEB_PERL_CHECK_ARGS) $(DEB_PERL_CHECK_FLAGS)))
	touch $@

# Drop packlist files after install, to respect Perl Policy 3.9.4 § 4.1
common-install-arch common-install-indep:: common-install-impl
common-install-impl::
	cd $(cdbs_perl_curbuilddir) && ./Build $(DEB_PERL_INSTALL_TARGET) $(DEB_PERL_INSTALL_ARGS) $(DEB_PERL_INSTALL_FLAGS)
	find $(cdbs_perl_curdestdir)/usr/lib -type f -name .packlist \
		-exec rm -f '{}' ';' \
		-exec sh -c "dirname '{}' | xargs rmdir --ignore-fail-on-non-empty -p" ';'

clean::
	-cd $(cdbs_perl_curbuilddir) && ./Build $(DEB_PERL_CLEAN_TARGET) $(DEB_PERL_CLEAN_ARGS) $(DEB_PERL_CLEAN_FLAGS)
	-rm -f debian/stamp-perl-build debian/stamp-perl-check

endif
