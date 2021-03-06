# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Colin Walters <walters@debian.org>
# Copyright © 2006 Marc Dequènes (Duck) <Duck@DuckCorp.org>
# Copyright © 2003,2006-2011 Jonas Smedegaard <dr@jones.dk>
# Description: Common variables for Python packages
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

ifndef _cdbs_class_python_vars
_cdbs_class_python_vars = 1

include $(_cdbs_rules_path)/buildvars.mk$(_cdbs_makefile_suffix)
include $(_cdbs_class_path)/langcore.mk$(_cdbs_makefile_suffix)

# By default the "python2" and "python3" packaging systems are used
# Possible alternatives are "pysupport" or "pycentral"
#DEB_PYTHON_SYSTEM =

# With "python2" and "python3", all likely packages are used by default
# These are tied together: Set one and default is none for the other
# NB! override needs to be done _before_ including this file!
#DEB_PYTHON2_MODULE_PACKAGES =
#DEB_PYTHON3_MODULE_PACKAGES =

# With "pysupport" and "pycentral", first likely package in
# 'debian/control' is used by default
# NB! override needs to be done _before_ including this file!
#DEB_PYTHON_MODULE_PACKAGES =

#DEB_PYTHON_PRIVATE_MODULES_DIRS =

#DEB_PYTHON_SRCDIR = $(DEB_DESTDIR)
#DEB_PYTHON_DESTDIR = $(DEB_DESTDIR)

cdbs_python_potential_packages = $(filter-out %-doc %-dev %-common, $(DEB_PACKAGES))
cdbs_python_legacy_packages = $(or $(DEB_PYTHON_MODULE_PACKAGES),$(firstword $(cdbs_python_potential_packages)))
cdbs_python2_packages = $(if $(DEB_PYTHON2_MODULE_PACKAGES)$(DEB_PYTHON3_MODULE_PACKAGES),$(DEB_PYTHON2_MODULE_PACKAGES),$(filter python-%,$(cdbs_python_potential_packages)))
cdbs_python3_packages = $(if $(DEB_PYTHON2_MODULE_PACKAGES)$(DEB_PYTHON3_MODULE_PACKAGES),$(DEB_PYTHON3_MODULE_PACKAGES),$(filter python3-%,$(cdbs_python_potential_packages)))
cdbs_python_packages = $(if $(DEB_PYTHON_SYSTEM),$(cdbs_python_legacy_packages),$(cdbs_python2_packages) $(cdbs_python3_packages))
cdbs_python2_arch_packages = $(filter $(cdbs_python2_packages),$(DEB_ARCH_PACKAGES))
cdbs_python3_arch_packages = $(filter $(cdbs_python3_packages),$(DEB_ARCH_PACKAGES))
cdbs_python_arch_packages = $(filter $(cdbs_python_packages),$(DEB_ARCH_PACKAGES))
cdbs_python2_indep_packages = $(filter $(cdbs_python2_packages),$(DEB_INDEP_PACKAGES))
cdbs_python3_indep_packages = $(filter $(cdbs_python3_packages),$(DEB_INDEP_PACKAGES))
cdbs_python_indep_packages = $(filter $(cdbs_python_packages), $(DEB_INDEP_PACKAGES))

cdbs_python_destdir = $(or $(DEB_PYTHON_DESTDIR),$(DEB_DESTDIR))

# check python system
cdbs_python_use_xs_field := $(if $(DEB_PYTHON_SYSTEM),$(shell grep -q "^XS-Python-Version:" debian/control && echo yes))
cdbs_python_selected_pyversions := $(if $(DEB_PYTHON_SYSTEM),$(shell if [ -e debian/pyversions ]; then cat debian/pyversions; fi))

cdbs_python2 = $(if $(DEB_PYTHON_SYSTEM),,$(if $(cdbs_python2_packages),python2))
cdbs_python3 = $(if $(DEB_PYTHON_SYSTEM),,$(if $(cdbs_python3_packages),python3))
cdbs_python_pysupport = $(filter pysupport,$(DEB_PYTHON_SYSTEM))
cdbs_python_pycentral = $(filter pycentral,$(DEB_PYTHON_SYSTEM))
cdbs_python_legacy_system = $(or $(cdbs_python_pysupport),$(cdbs_python_pycentral),$(error unsupported Python system: $(DEB_PYTHON_SYSTEM) (select either pysupport or pycentral, or leave empty for default python2/python3)))
cdbs_python_systems = $(if $(DEB_PYTHON_SYSTEM),$(cdbs_python_legacy_system),$(if $(cdbs_python2_packages),python2) $(if $(cdbs_python3_packages),python3))
cdbs_curpythonsystems = $(if $(DEB_PYTHON_SYSTEM),$(cdbs_python_legacy_system),$(strip $(if $(filter $(cdbs_curpkg),$(cdbs_python2_packages)),python2) $(if $(filter $(cdbs_curpkg),$(cdbs_python3_packages)),python3)))

cdbs_python_stem = $(if $(DEB_PYTHON_SYSTEM),,$(if $(cdbs_python3_packages),3))
cdbs_python_stem += $(if $(word 2,$(cdbs_python_systems)),$(error use of both "python2" and "python3" packaging systems is unsupported here - either change target binary package names, explicitly set DEB_PYTHON2_PACKAGES and/or DEB_PYTHON3_PACKAGES or set an alternative DEB_PYTHON_SYSTEM))
cdbs_curpythonstem = $(if $(cdbs_python_single_system),$(cdbs_python_stem),$(if $(filter $(cdbs_curpkg),$(cdbs_python3_packages)),3))

cdbs_python_current_binary := $(if $(DEB_PYTHON_SYSTEM)$(cdbs_python2),$(shell pyversions -d))
cdbs_python3_current_binary := $(if $(cdbs_python3),$(shell py3versions -d))
cdbs_python_binary = $(if $(call cdbs_streq,$(cdbs_python$(cdbs_curpythonstem)_current_binary),$(1)),python$(cdbs_curpythonstem),$(1))

# Calculate cdbs_python_build_versions
cdbs_python_current_version := $(if $(DEB_PYTHON_SYSTEM)$(cdbs_python2),$(shell pyversions -vd))
cdbs_python3_current_version := $(if $(cdbs_python3),$(shell py3versions -vd))
cdbs_python_supported_versions := $(if $(DEB_PYTHON_SYSTEM)$(cdbs_python2),$(shell pyversions -vr))
cdbs_python3_supported_versions := $(if $(cdbs_python3),$(shell py3versions -vr))
cdbs_python_first_supported_version = $(firstword $(strip $(sort $(cdbs_python_supported_versions))))
cdbs_python3_first_supported_version = $(firstword $(strip $(sort $(cdbs_python3_supported_versions))))

# Non-default Python version used (only valid for arch-indendent builds)
# arch(+indep): none; indep: none if current is supported, else first supported
cdbs_python_nondefault_version = $(if $(cdbs_python_arch_packages),,$(if $(filter $(cdbs_python_current_version),$(cdbs_python_supported_versions)),,$(cdbs_python_first_supported_version)))
cdbs_python3_nondefault_version = $(if $(cdbs_python_arch_packages),,$(if $(filter $(cdbs_python3_current_version),$(cdbs_python3_supported_versions)),,$(cdbs_python3_first_supported_version)))
cdbs_curpythonindepbinary = python$(or $(cdbs_python$(cdbs_curpythonstem)_nondefault_version),$(cdbs_curpythonstem))

cdbs_python_primary_version = $(or $(cdbs_python_nondefault_version),$(cdbs_python_current_version))
cdbs_python3_primary_version = $(or $(cdbs_python3_nondefault_version),$(cdbs_python3_current_version))
cdbs_curpythonpribinary = python$(cdbs_python$(cdbs_curpythonstem)_primary_version)

# arch(+indep): all; indep: current if supported, else first supported
cdbs_python_build_versions = $(or $(if $(cdbs_python_arch_packages),$(cdbs_python_supported_versions)),$(cdbs_python_primary_version))
cdbs_python3_build_versions = $(or $(if $(cdbs_python_arch_packages),$(cdbs_python3_supported_versions)),$(cdbs_python3_primary_version))
cdbs_curpythonbuildversions = $(cdbs_python$(cdbs_curpythonstem)_build_versions)

# Python-related dependencies according to Python policy, appendix A
#  * Arch-independent Python 3 was broken until 0.4.93~
cdbs_python_builddeps_legacy = $(if $(DEB_PYTHON_SYSTEM),$(if $(cdbs_python_arch_packages),python-all-dev,python-dev (>= 2.3.5-7)$(cdbs_python_nondefault_version:%=, python%-dev)))
cdbs_python2_builddeps = $(if $(cdbs_python2),$(if $(cdbs_python2_arch_packages),python-all-dev,python-dev (>= 2.3.5-7)$(cdbs_python_nondefault_version:%=, python%-dev)))
cdbs_python3_builddeps = $(if $(cdbs_python3),$(if $(cdbs_python3_arch_packages),python3-all-dev (>= 3.1),python3-dev$(cdbs_python3_nondefault_version:%=, python%-dev)))
cdbs_python_builddeps = $(cdbs_python_builddeps_legacy), $(cdbs_python2_builddeps), $(cdbs_python3_builddeps)
cdbs_python_builddeps_cdbs = $(if $(cdbs_python3_indep_packages),$(comma) cdbs (>= 0.4.93~),$(if $(cdbs_python2)$(cdbs_python3),$(comma) cdbs (>= 0.4.90~)))

# warning pysupport compatibility mode
$(if $(cdbs_python_pysupport),$(if $(cdbs_python_use_xs_field),$(warning WARNING:  Use of XS-Python-Version and XB-Python-Version fields in debian/control is deprecated with pysupport method; use debian/pyversions if you need to specify specific versions.)))

# check if build is possible
$(if $(cdbs_python_pysupport),$(if $(cdbs_python_build_versions),,$(error invalid setting in debian/pyversions)))
$(if $(cdbs_python_pycentral),$(if $(cdbs_python_build_versions),,$(error invalid setting for XS-Python-Version)))
$(if $(cdbs_python2),$(if $(cdbs_python_build_versions),,$(error invalid setting for X-Python-Version)))
$(if $(cdbs_python3),$(if $(cdbs_python3_build_versions),,$(error invalid setting for X-Python3-Version)))

endif
