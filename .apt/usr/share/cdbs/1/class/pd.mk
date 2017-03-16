# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2010 IOhannes m zmölnig <zmoelnig@iem.at>
# Copyright © 2011 Jonas Smedegaard <dr@jones.dk>
# Description: packaging routines for puredata
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

####
# this snippet will take care of properly handling the uncommon suffix of
# pd-externals (.pd_linux for dlopen()ed plugins), which otherwise are not
# handled by shlibdeps/strip
#
# TODO
#   automatic handling of LICENSE.txt
#   ...
####

_cdbs_scripts_path ?= /usr/lib/cdbs
_cdbs_rules_path ?= /usr/share/cdbs/1/rules
_cdbs_class_path ?= /usr/share/cdbs/1/class

ifndef _cdbs_class_pd
_cdbs_class_pd := 1

include $(_cdbs_rules_path)/buildcore.mk$(_cdbs_makefile_suffix)

# Tighten to versions of cdbs providing this snippet
CDBS_BUILD_DEPENDS_class_pd ?= cdbs (>= 0.4.91~)
CDBS_BUILD_DEPENDS += , $(CDBS_BUILD_DEPENDS_class_pd)

testsanity::
	$(if $(_cdbs_rules_debhelper),,$(warning WARNING: debhelper rule not used. Make sure to then manually include pd targets!))

# pd externals have the uncommon extension .pd_linux, which prevents them from
# being properly detected by dh_shlibdeps, so we do it manually
$(patsubst %,binary-strip-IMPL/%,$(DEB_ALL_PACKAGES)) ::
	$(if $(is_debug_package)$(filter nostrip,$(DEB_BUILD_OPTIONS)),,find "$(CURDIR)/debian/$(cdbs_curpkg)" -name "*.pd_linux" -exec strip --remove-section=.comment --remove-section=.note --strip-unneeded {} +)
$(patsubst %,binary-predeb-IMPL/%,$(DEB_ALL_PACKAGES)) ::
	find "$(CURDIR)/debian/$(cdbs_curpkg)" -name "*.pd_linux" -exec dpkg-shlibdeps -Tdebian/$(cdbs_curpkg).substvars {} +
	find "$(CURDIR)/debian/$(cdbs_curpkg)" -name "*.pd_linux" -exec chmod 0644 {} +

#endif _cdbs_class_pd
endif
