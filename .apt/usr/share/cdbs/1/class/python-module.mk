# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Colin Walters <walters@debian.org>
# Copyright © 2006 Marc Dequènes (Duck) <Duck@DuckCorp.org>
# Copyright © 2003,2006-2011 Jonas Smedegaard <dr@jones.dk>
# Description: Rules common to Python module packaging
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

ifndef _cdbs_class_python_module
_cdbs_class_python_module = 1

include $(_cdbs_rules_path)/buildcore.mk$(_cdbs_makefile_suffix)
include $(_cdbs_class_path)/python-vars.mk$(_cdbs_makefile_suffix)

# This variable is deprecated.
_cdbs_deprecated_vars += DEB_PYTHON_PRIVATE_MODULES_DIRS
# New in 0.4.97.
DEB_PYTHON_PRIVATE_MODULES_DIRS_ALL ?= $(DEB_PYTHON_PRIVATE_MODULES_DIRS)

# pysupport/pycentral dependencies according to Python policy, appendix A
CDBS_BUILD_DEPENDS_class_python-module_pysupport ?= python-support
CDBS_BUILD_DEPENDS += $(if $(cdbs_python_pysupport),$(comma) $(CDBS_BUILD_DEPENDS_class_python-module_pysupport))

CDBS_BUILD_DEPENDS_class_python-module_pycentral ?= python-central
CDBS_BUILD_DEPENDS += $(if $(cdbs_python_pycentral),$(comma) $(CDBS_BUILD_DEPENDS_class_python-module_pycentral))

# dh_python2 comes from python package
CDBS_BUILD_DEPENDS_class_python-module_python2 ?= python
CDBS_BUILD_DEPENDS += $(if $(cdbs_python2),$(comma) $(CDBS_BUILD_DEPENDS_class_python-module_python2))

CDBS_BUILD_DEPENDS_class_python-module_python3 ?= python3
CDBS_BUILD_DEPENDS += $(if $(cdbs_python3),$(comma) $(CDBS_BUILD_DEPENDS_class_python-module_python3))

CDBS_BUILD_DEPENDS_class_python-module_args ?= cdbs (>= 0.4.97~)
CDBS_BUILD_DEPENDS += $(if $(call cdbs_expand_allvars,DEB_DH_PYTHONHELPER_ARGS DEB_PYTHON_PRIVATE_MODULES_DIRS),$(comma) $(CDBS_BUILD_DEPENDS_class_python-module_args))

$(patsubst %,testsanity/%,$(DEB_ALL_PACKAGES)) :: testsanity/% : 
	$(if $(word 2,$(cdbs_curpythonsystems)),$(error binary package $(cdbs_curpkg) use both "python2" and "python3" packaging systems - either explicitly set DEB_PYTHON2_PACKAGES and/or DEB_PYTHON3_PACKAGES or set an alternative DEB_PYTHON_SYSTEM))

# Optionally use debhelper (if not then these rules are simply ignored)
# * invoke for all binary packages with legacy helpers (see bug#377965)
# * invoke public and private modules separately with default helpers
$(patsubst %,binary-post-install/%,$(DEB_PACKAGES)) :: binary-post-install/%: binary-install-python/%
$(patsubst %,binary-install-python/%,$(DEB_PACKAGES)) :: binary-install-python/%: binary-install/%
	$(if $(DEB_PYTHON_SYSTEM),dh_$(cdbs_curpythonsystems) -p$(cdbs_curpkg) $(call cdbs_expand_curvar,DEB_DH_PYTHONHELPER_ARGS) $(call cdbs_expand_curvar,DEB_PYTHON_PRIVATE_MODULES_DIRS))
	$(if $(DEB_PYTHON_SYSTEM),,$(if $(cdbs_curpythonsystems),dh_$(cdbs_curpythonsystems) -p$(cdbs_curpkg) $(call cdbs_expand_curvar,DEB_DH_PYTHONHELPER_ARGS)))
	$(if $(DEB_PYTHON_SYSTEM),,$(and $(cdbs_curpythonsystems),$(call cdbs_expand_curvar,DEB_PYTHON_PRIVATE_MODULES_DIRS),dh_$(cdbs_curpythonsystems) -p$(cdbs_curpkg) $(call cdbs_expand_curvar,DEB_DH_PYTHONHELPER_ARGS) $(call cdbs_expand_curvar,DEB_PYTHON_PRIVATE_MODULES_DIRS)))

endif
