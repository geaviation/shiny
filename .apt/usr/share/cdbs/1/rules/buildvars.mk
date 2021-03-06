# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2002,2003 Colin Walters <walters@debian.org>
# Copyright © 2009-2011 Jonas Smedegaard <dr@jones.dk>
# Description: Defines some useful variables, but no rules
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

ifndef _cdbs_rules_buildvars
_cdbs_rules_buildvars = 1

CDBS_VERSION = something

# Common useful variables
DEB_SOURCE_PACKAGE := $(strip $(shell egrep '^Source: ' debian/control | cut -f 2 -d ':'))
DEB_VERSION := $(shell dpkg-parsechangelog | egrep '^Version:' | cut -f 2 -d ' ')
DEB_NOEPOCH_VERSION := $(shell echo $(DEB_VERSION) | cut -d: -f2-)
DEB_UPSTREAM_VERSION := $(shell echo $(DEB_NOEPOCH_VERSION) | sed 's/-[^-]*$$//')
DEB_ISNATIVE := $(shell dpkg-parsechangelog | egrep '^Version:' | perl -ne 'print if not /^Version:\s*.*-/;')

# Split into arch/indep packages
ifneq ($(DEB_INDEP_PACKAGES),cdbs)
ifdef _cdbs_rules_debhelper
# This odd piece of coding is necessary to hide the warning message
# "I have no package to build" while preserving genuine error messages.
# This was in fact an error before debhelper 5.0.30.
# FIXME: revert: debhelper 5.0.30 is in stable!
DEB_INDEP_PACKAGES := $(strip $(shell dh_listpackages -i 2>/dev/null || dh_listpackages -i))
DEB_ARCH_PACKAGES := $(filter-out $(DEB_INDEP_PACKAGES),$(strip $(shell dh_listpackages -s 2>/dev/null || dh_listpackages -s)))
else
DEB_INDEP_PACKAGES := $(strip $(shell $(_cdbs_scripts_path)/list-packages indep))
DEB_ARCH_PACKAGES := $(filter-out $(DEB_INDEP_PACKAGES),$(strip $(shell $(_cdbs_scripts_path)/list-packages same)))
endif
endif
# Split into normal and udeb packages
ifeq ($(DEB_UDEB_PACKAGES),)
DEB_PACKAGES ?= $(filter-out %-udeb, $(DEB_ARCH_PACKAGES) $(DEB_INDEP_PACKAGES))
DEB_UDEB_PACKAGES ?= $(filter %-udeb, $(DEB_ARCH_PACKAGES) $(DEB_INDEP_PACKAGES))
else
DEB_PACKAGES ?= $(filter-out $(DEB_UDEB_PACKAGES), $(DEB_ARCH_PACKAGES) $(DEB_INDEP_PACKAGES))
endif
# Too much bother for now.  If someone complains we'll fix it.
#DEB_ARCH_UDEB_PACKAGES = $(filter %-udeb, $(DEB_ARCH_PACKAGES))
#DEB_INDEP_UDEB_PACKAGES = $(filter %-udeb, $(DEB_INDEP_PACKAGES))
# A handy list of every package, udeb or not
DEB_ALL_PACKAGES ?= $(DEB_PACKAGES) $(DEB_UDEB_PACKAGES)
DEB_INDEP_REGULAR_PACKAGES ?= $(filter-out $(DEB_UDEB_PACKAGES),$(DEB_INDEP_PACKAGES))
DEB_ARCH_REGULAR_PACKAGES ?= $(filter-out $(DEB_UDEB_PACKAGES),$(DEB_ARCH_PACKAGES))

DEB_DBG_PACKAGES ?= $(filter %-dbg, $(DEB_ARCH_PACKAGES) $(DEB_INDEP_PACKAGES))

# Some support for srcdir != builddir builds.
# These are relative to the root of the package
DEB_SRCDIR ?= .
DEB_BUILDDIR ?= $(strip $(DEB_SRCDIR))

# Miscellaneous bits
# TODO: Drop this when safe (dpkg-buildpackage exports them but since when?)
DEB_ARCH = $(shell dpkg --print-architecture)
DEB_HOST_GNU_TYPE ?= $(shell dpkg-architecture -qDEB_HOST_GNU_TYPE)
DEB_HOST_GNU_SYSTEM ?= $(shell dpkg-architecture -qDEB_HOST_GNU_SYSTEM)
DEB_HOST_GNU_CPU ?= $(shell dpkg-architecture -qDEB_HOST_GNU_CPU)
DEB_HOST_ARCH ?= $(shell dpkg-architecture -qDEB_HOST_ARCH)
DEB_HOST_ARCH_CPU ?= $(shell dpkg-architecture -qDEB_HOST_ARCH_CPU)
DEB_HOST_ARCH_OS ?= $(shell dpkg-architecture -qDEB_HOST_ARCH_OS)
DEB_HOST_MULTIARCH ?= $(shell dpkg-architecture -qDEB_HOST_MULTIARCH)
DEB_BUILD_GNU_TYPE ?= $(shell dpkg-architecture -qDEB_BUILD_GNU_TYPE)
DEB_BUILD_GNU_SYSTEM ?= $(shell dpkg-architecture -qDEB_BUILD_GNU_SYSTEM)
DEB_BUILD_GNU_CPU ?= $(shell dpkg-architecture -qDEB_BUILD_GNU_CPU)
DEB_BUILD_ARCH ?= $(shell dpkg-architecture -qDEB_BUILD_ARCH)
DEB_BUILD_ARCH_CPU ?= $(shell dpkg-architecture -qDEB_BUILD_ARCH_CPU)
DEB_BUILD_ARCH_OS ?= $(shell dpkg-architecture -qDEB_BUILD_ARCH_OS)

ifeq ($(words $(DEB_ALL_PACKAGES)),1)
	DEB_DESTDIR ?= $(CURDIR)/debian/$(strip $(DEB_ALL_PACKAGES))/
else
	DEB_DESTDIR ?= $(CURDIR)/debian/tmp/
endif

CDBS_BUILD_DEPENDS_rules_buildvars ?= cdbs
CDBS_BUILD_DEPENDS += , $(CDBS_BUILD_DEPENDS_rules_buildvars)

# Internal useful variables/expansions

# Can we change this to cdbs_curpkg = $(notdir $@) ?
cdbs_curpkg = $(filter-out %/,$(subst /,/ ,$@))

is_debug_package=$(if $(patsubst %-dbg,,$(cdbs_curpkg)),,yes)

cdbs_cursrcdir = $(or $(DEB_PKGSRCDIR_$(cdbs_curpkg)),$(DEB_SRCDIR))
cdbs_curbuilddir = $(or $(DEB_BUILDDIR_$(cdbs_curpkg)),$(DEB_BUILDDIR))
cdbs_curdestdir = $(or $(DEB_DESTDIR_$(cdbs_curpkg)),$(DEB_DESTDIR))

cdbs_streq = $(if $(filter-out xx,x$(subst $1,,$2)$(subst $2,,$1)x),,yes)

nullstring =
space = $(nullstring) # <- notice the trailing space (only leading is stripped)
comma = ,
open_parenthesis = (
close_parenthesis = )
cdbs_delimit = $(firstword $1)$(foreach word,$(wordlist 2,$(words $1),$1),$2$(word))

# Resolve VAR_ALL and either VAR_pkg or VAR_DEFAULT, space- or custom-delimited
#  * VAR_ALL applies to all packages
#  * VAR_pkg applies to current package
#  * VAR_DEFAULT applies to current package if not overridden by VAR_pkg
cdbs_expand_curvar = $($(1)_ALL)$(if $($(1)_ALL),$(or $2,$(space)))$(if $(filter-out $(origin $(1)_$(cdbs_curpkg)),undefined),$($(1)_$(cdbs_curpkg)),$($(1)_DEFAULT))
cdbs_expand_allvars = $(foreach stem,$(1),$($(stem)_ALL)$($(stem))$(foreach pkg,$(DEB_ALL_PACKAGES),$($(stem)_$(pkg))))

# List "packages multiplied with branches", or just packages if no branches
# Syntax: PACKAGES BRANCHES WORDDELIMITER BRANCHDELIMITER [FALLBACK-MAIN-BRANCH]
cdbs_expand_branches = $(subst WORDDELIMITER,$3,$(subst BRANCHDELIMITER,$4,$(call cdbs_delimit,$(if $2,$(foreach pkg,$1,$(call cdbs_delimit,$(foreach branch,$2,$(pkg)$(branch:%=-%)),BRANCHDELIMITER)),$(if $5,$(foreach pkg,$1,$(pkg)-$(5)BRANCHDELIMITER$(pkg)),$1)),WORDDELIMITER)))

cdbs_findargs-path-or-name = $(if $(findstring /,$(firstword $(1))),-path './$(patsubst ./%,%,$(firstword $(1)))',-name '$(firstword $(1))') $(foreach obj,$(wordlist 2,$(words $(1)),$(1)),-or $(if $(findstring /,$(obj)),-path './$(obj:./%=%)',-name '$(obj)'))

# Resolve VAR only if declared explicitly in makefile or environment
cdbs_expand_nondefaultvar = $(if $(filter-out undefined default,$(origin $1)),$($1),$(2))

# Declare (shell-style) variables to itself if explicitly declared
cdbs_set_nondefaultvar = $(if $(filter-out $(origin $1),default),$1="$($1)")
cdbs_set_nondefaultvars = $(foreach var,$1,$(call cdbs_set_nondefaultvar,$(var)))

# Return non-empty if build system is different from host system
cdbs_crossbuild = $(if $(call cdbs_streq,$(DEB_BUILD_GNU_TYPE),$(DEB_HOST_GNU_TYPE)),,yes)

endif
