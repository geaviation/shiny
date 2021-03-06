# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Stefan Gybas <sgybas@debian.org>
# Description: Builds and cleans packages which have an Ant build.xml file
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

ifndef _cdbs_class_ant
_cdbs_class_ant = 1

include $(_cdbs_rules_path)/buildcore.mk$(_cdbs_makefile_suffix)
include $(_cdbs_class_path)/ant-vars.mk$(_cdbs_makefile_suffix)

testsanity::
	@if ! test -x "$(firstword $(JAVACMD))"; then \
		echo "You must specify a valid JAVA_HOME or JAVACMD!"; \
		exit 1; \
	fi
	@if ! test -r "$(ANT_HOME)/lib/ant.jar"; then \
		echo "You must specify a valid ANT_HOME directory!"; \
		exit 1; \
	fi

common-build-arch common-build-indep:: debian/stamp-ant-build
debian/stamp-ant-build:
	$(DEB_ANT_INVOKE) $(DEB_ANT_BUILD_TARGET)
	touch debian/stamp-ant-build

clean::
	-$(DEB_ANT_INVOKE) $(DEB_ANT_CLEAN_TARGET)
	rm -f debian/stamp-ant-build

common-install-arch common-install-indep:: common-install-impl
common-install-impl::
	$(if $(DEB_ANT_INSTALL_TARGET),$(DEB_ANT_INVOKE) $(DEB_ANT_INSTALL_TARGET),@echo "DEB_ANT_INSTALL_TARGET unset, skipping default ant.mk common-install target")

ifeq (,$(filter nocheck,$(DEB_BUILD_OPTIONS)))
common-build-arch common-build-indep:: debian/stamp-ant-check
debian/stamp-ant-check: debian/stamp-ant-build
	$(if $(DEB_ANT_CHECK_TARGET),$(DEB_ANT_INVOKE) $(DEB_ANT_CHECK_TARGET),@echo "DEB_ANT_CHECK_TARGET unset, not running checks")
	$(if $(DEB_ANT_CHECK_TARGET),touch $@)

clean::
	$(if $(DEB_ANT_CHECK_TARGET),rm -f debian/stamp-ant-check)
endif

endif
