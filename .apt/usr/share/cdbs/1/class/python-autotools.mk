# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2008-2011 Jonas Smedegaard <dr@jones.dk>
# Description: Class to configure + build GNU autoconf+automake+python packages
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

ifndef _cdbs_class_python_autotools
_cdbs_class_python_autotools = 1

include $(_cdbs_class_path)/python-module.mk$(_cdbs_makefile_suffix)

# Flavors are used if more than a single Python build is needed
# Used in implicit rules, so must be set before including makefile
DEB_MAKE_FLAVORS ?= $(if $(word 2,$(cdbs_python_build_versions)),$(cdbs_python_build_versions))

include $(_cdbs_class_path)/autotools.mk$(_cdbs_makefile_suffix)

# Build-time per-package variables conflict with with flavor variables
cdbs_python_single_system = true

CDBS_BUILD_DEPENDS_class_python-autotools ?= $(cdbs_python_builddeps_cdbs)
CDBS_BUILD_DEPENDS += , $(CDBS_BUILD_DEPENDS_class_python-autotools)

# Python-related dependencies according to Python policy, appendix A
CDBS_BUILD_DEPENDS_class_python-autotools_python ?= $(cdbs_python_builddeps)
CDBS_BUILD_DEPENDS += , $(CDBS_BUILD_DEPENDS_class_python-autotools_python)

# FIXME: Restructure to allow early override
DEB_CONFIGURE_SCRIPT_ENV += PYTHON="$(or $(python$(cdbs_python$(cdbs_curpythonstem)_nondefault_version):%=python%),$(call cdbs_python_binary,python$(if $(cdbs_make_flavors),$(cdbs_make_curflavor))))"

# Install all flavors on top of each other by default
DEB_MAKE_DESTDIRSKEL = $(cdbs_curdestdir)

endif
