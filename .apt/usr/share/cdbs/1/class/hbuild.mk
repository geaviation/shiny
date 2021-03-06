# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Colin Walters <walters@debian.org>
# Description: configure, compile, binary, and clean Haskell libraries and programs
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

ifndef _cdbs_class_hbuild
_cdbs_class_hbuild = 1

include $(_cdbs_rules_path)/buildcore.mk$(_cdbs_makefile_suffix)
include $(_cdbs_class_path)/langcore.mk$(_cdbs_makefile_suffix)

# TODO: Make these overridable (i.e. uppercase them) and allow early override
cdbs_hugs_packages = $(filter %-hugs,$(DEB_PACKAGES))
cdbs_ghc_packages = $(filter %-ghc,$(DEB_PACKAGES))

DEB_HBUILD_SETUPFILE ?= $(firstword $(wildcard $(DEB_SRCDIR)/Setup.lhs $(DEB_SRCDIR)/Setup.hs))

DEB_HBUILD_INVOKE ?= $(DEB_HBUILD_SETUPFILE) --noreg --runfrom="" --prefix=debian/$(cdbs_curpkg) 

clean::
	$(DEB_HBUILD_SETUPFILE) allclean

$(patsubst %,install/%,$(cdbs_hugs_packages)) :: install/% :
	$(DEB_HBUILD_INVOKE) install-hugs
$(patsubst %,install/%,$(cdbs_ghc_packages)) :: install/% :
	$(DEB_HBUILD_INVOKE) install-ghc

endif
