# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Colin Walters <walters@debian.org>
# Copyright © 2006 Marc Dequènes (Duck) <Duck@DuckCorp.org>
# Copyright © 2003,2006-2011 Jonas Smedegaard <dr@jones.dk>
# Description: manage Python modules using the 'distutils' build system
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

ifndef _cdbs_class_python_distutils
_cdbs_class_python_distutils = 1

include $(_cdbs_class_path)/python-module.mk$(_cdbs_makefile_suffix)

#DEB_PYTHON_DISTUTILS_SRCDIR = $(DEB_SRCDIR)

DEB_PYTHON_SETUP_CMD ?= setup.py
DEB_PYTHON_BUILD_ARGS ?= --build-base="$(CURDIR)/$(cdbs_curbuilddir)/build"
DEB_PYTHON_INSTALL_ARGS_ALL ?= --prefix=/usr --no-compile -O0
DEB_PYTHON_CLEAN_ARGS ?= -a
#DEB_PYTHON_DISTUTILS_INSTALLDIR_SKEL = /usr/lib/@PYTHONBINARY@/site-packages/

# This variable was deprecated after cdbs 0.4.89
_cdbs_deprecated_vars += DEB_PYTHON_SETUP_CMD
_cdbs_deprecated_DEB_PYTHON_SETUP_CMD_default := $(DEB_PYTHON_SETUP_CMD)
DEB_PYTHON_SETUP_CMD_DEFAULT ?= $(DEB_PYTHON_SETUP_CMD)

# This variable was deprecated after cdbs 0.4.89
_cdbs_deprecated_vars += DEB_PYTHON_BUILD_ARGS
_cdbs_deprecated_DEB_PYTHON_BUILD_ARGS_default := $(DEB_PYTHON_BUILD_ARGS)
DEB_PYTHON_BUILD_ARGS_DEFAULT ?= $(DEB_PYTHON_BUILD_ARGS)

# This variable was deprecated after cdbs 0.4.89
_cdbs_deprecated_vars += DEB_PYTHON_CLEAN_ARGS
_cdbs_deprecated_DEB_PYTHON_CLEAN_ARGS_default := $(DEB_PYTHON_CLEAN_ARGS)
DEB_PYTHON_CLEAN_ARGS_DEFAULT ?= $(DEB_PYTHON_CLEAN_ARGS)

# DEB_PYTHON_MODULE_PACKAGE is deprecated.
# use DEB_PYTHON_MODULE_PACKAGES instead (since CDBS 0.4.54)
# (warn even when used as-is: plural form breaks use in build targets)
DEB_PYTHON_MODULE_PACKAGE = $(warning Use of DEB_PYTHON_MODULE_PACKAGE is deprecated, please use DEB_PYTHON_MODULE_PACKAGES instead)$(firstword $(filter-out %-doc %-dev %-common, $(DEB_PACKAGES)))

cdbs_python_distutils_srcdir = $(or $(DEB_PYTHON_DISTUTILS_SRCDIR),$(DEB_SRCDIR))
cdbs_python_setup_cmd = $(call cdbs_expand_curvar,DEB_PYTHON_SETUP_CMD)
cdbs_python_build_args = $(call cdbs_expand_curvar,DEB_PYTHON_BUILD_ARGS)
cdbs_python_install_args = $(call cdbs_expand_curvar,DEB_PYTHON_INSTALL_ARGS)
cdbs_python_clean_args = $(call cdbs_expand_curvar,DEB_PYTHON_CLEAN_ARGS)
cdbs_expand_python_distutils_installdir = $(subst @PYTHONBINARY@,$1,$(or $(DEB_PYTHON_DISTUTILS_INSTALLDIR_SKEL),/usr/lib/@PYTHONBINARY@/site-packages/))

# prepare sanity checks
cdbs_python_packages_pre := $(cdbs_python_arch_packages)$(cdbs_python_indep_packages)
cdbs_python_pkgresolve_check = $(if $(call cdbs_streq,$(cdbs_python_arch_packages)$(cdbs_python_indep_packages),$(cdbs_python_packages_pre)),,$(warning WARNING: Redefining DEB_PYTHON_MODULE_PACKAGES late is currently unsupported: set DEB_PYTHON_MODULE_PACKAGES before including python-distutils.mk))
## TODO: Rephrase when DEB_PYTHON_MODULE_PACKAGES is only expanded inside rules
cdbs_python_pkg_check = $(if $(cdbs_python_arch_packages)$(cdbs_python_indep_packages),,$(warning WARNING: No Python packages found or declared - either rename binary packages or set DEB_PYTHON_MODULE_PACKAGES before including python-distutils.mk))

CDBS_BUILD_DEPENDS_class_python-distutils ?= $(cdbs_python_builddeps_cdbs)
CDBS_BUILD_DEPENDS += , $(CDBS_BUILD_DEPENDS_class_python-distutils)

CDBS_BUILD_DEPENDS_cdbs_python-distutils_srcdir ?= cdbs (>= 0.4.97~)
CDBS_BUILD_DEPENDS += $(if $(DEB_PYTHON_DISTUTILS_SRCDIR),$(CDBS_BUILD_DEPENDS_cdbs_python-distutils_srcdir))

CDBS_BUILD_DEPENDS_cdbs_python-distutils_installdir ?= cdbs (>= 0.4.91~)
CDBS_BUILD_DEPENDS += $(if $(DEB_PYTHON_DISTUTILS_INSTALLDIR_SKEL),$(CDBS_BUILD_DEPENDS_cdbs_python-distutils_installdir))

# Python-related dependencies according to Python policy, appendix A
CDBS_BUILD_DEPENDS_class_python-distutils_python ?= $(cdbs_python_builddeps)
CDBS_BUILD_DEPENDS += , $(CDBS_BUILD_DEPENDS_class_python-distutils_python)

# warn about wrong number of resolved Python packages
CDBS_BUILD_DEPENDS += $(cdbs_python_pkg_check)

# warn early about late changes to DEB_PYTHON_MODULES_PACKAGES
testsanity::
	$(cdbs_python_pkgresolve_check)

pre-build::
	mkdir -p debian/python-module-stampdir

# build stage
common-build-arch common-build-indep:: $(addprefix python-build-stamp-, $(cdbs_python_build_versions))

$(patsubst %,build/%,$(cdbs_python_indep_packages) $(cdbs_python_arch_packages)) :: build/% : debian/python-module-stampdir/%

$(patsubst %,debian/python-module-stampdir/%,$(cdbs_python_indep_packages)) :: debian/python-module-stampdir/%:
	cd $(cdbs_python_distutils_srcdir) && \
		$(cdbs_curpythonindepbinary) $(cdbs_python_setup_cmd) build \
		$(cdbs_python_build_args)
	touch $@

$(patsubst %,debian/python-module-stampdir/%,$(cdbs_python_arch_packages)) :: debian/python-module-stampdir/%:
	set -e; for buildver in $(cdbs_curpythonbuildversions); do \
		cd $(CURDIR) && cd $(cdbs_python_distutils_srcdir) && \
			$(call cdbs_python_binary,python$$buildver) $(cdbs_python_setup_cmd) build \
			$(cdbs_python_build_args); \
	done
	touch $@


# install stage
$(patsubst %,install/%,$(cdbs_python_indep_packages)) :: install/%: python-install-py
	cd $(cdbs_python_distutils_srcdir) && \
		$(cdbs_curpythonindepbinary) $(cdbs_python_setup_cmd) install \
		--root="$(cdbs_python_destdir)" \
		--install-purelib=$(call cdbs_expand_python_distutils_installdir,$(cdbs_curpythonpribinary)) \
		$(cdbs_python_install_args)

$(patsubst %,install/%,$(cdbs_python_arch_packages)) :: install/%: $(addprefix python-install-, $(cdbs_python_build_versions))
	set -e; for buildver in $(cdbs_curpythonbuildversions); do \
		cd $(CURDIR) && cd $(cdbs_python_distutils_srcdir) && \
			$(call cdbs_python_binary,python$$buildver) $(cdbs_python_setup_cmd) install \
			--root="$(cdbs_python_destdir)" \
			--install-purelib=$(call cdbs_expand_python_distutils_installdir,python$$buildver) \
			--install-platlib=$(call cdbs_expand_python_distutils_installdir,python$$buildver) \
			$(cdbs_python_install_args); \
	done

# Deprecated targets.  You should use above targets instead.
$(addprefix python-build-stamp-, $(cdbs_python_build_versions)):
python-install-py $(addprefix python-install-, $(cdbs_python_build_versions)):


# clean stage
clean:: $(patsubst %,python-module-clean/%,$(cdbs_python_indep_packages) $(cdbs_python_arch_packages)) $(addprefix python-clean-, $(cdbs_python_build_versions))

$(patsubst %,python-module-clean/%,$(cdbs_python_indep_packages)) :: python-module-clean/%:
	-cd $(cdbs_python_distutils_srcdir) && \
		$(cdbs_curpythonindepbinary) $(cdbs_python_setup_cmd) clean \
		$(cdbs_python_clean_args)

$(patsubst %,python-module-clean/%,$(cdbs_python_arch_packages)) :: python-module-clean/%:
	-for buildver in $(cdbs_curpythonbuildversions); do \
		cd $(CURDIR) && cd $(cdbs_python_distutils_srcdir) && \
			$(call cdbs_python_binary,python$$buildver) $(cdbs_python_setup_cmd) clean \
			$(cdbs_python_clean_args); \
	done

# Deprecated targets.  You should use above targets instead.
$(addprefix python-clean-, $(cdbs_python_build_versions)):

# cleanup stamp dir
# (dh_clean choke on dirs named stamp, so need to happen before clean::)
clean:: clean-python-distutils
clean-python-distutils::
	rm -rf debian/python-module-stampdir

# Calling "setup.py clean" may create .pyc files and __pycache__
# directories, so we need a final cleanup pass here.
# Also clean up .egg-info files generated by setuptools
clean::
	find "$(CURDIR)" -name '*.py[co]' -delete
	find "$(CURDIR)" -name __pycache__ -type d -empty -delete
	find "$(CURDIR)" -prune -name '*.egg-info' -exec rm -rf '{}' ';'

.PHONY: $(patsubst %,python-module-clean/%,$(cdbs_python_indep_packages) $(cdbs_python_arch_packages))
endif
