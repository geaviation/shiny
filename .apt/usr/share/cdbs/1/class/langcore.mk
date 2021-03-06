# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2002,2003 Colin Walters <walters@debian.org>
# Copyright © 2011 Jonas Smedegaard <dr@jones.dk>
# Description: Sets core language variables, such as CFLAGS and CXXFLAGS
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

ifndef _cdbs_class_langcore
_cdbs_class_langcore = 1


# Resolve our defaults
ifneq (,$(wildcard /usr/bin/dpkg-buildflags))
deb_cflags := $(shell dpkg-buildflags --get CFLAGS)
deb_cppflags := $(shell dpkg-buildflags --get CPPFLAGS)
deb_cxxflags := $(shell dpkg-buildflags --get CXXFLAGS)
deb_fflags := $(shell dpkg-buildflags --get FFLAGS)
deb_ldflags := $(shell dpkg-buildflags --get LDFLAGS)
else
# TODO: Use above unconditionally when oldstable has dpkg >= 1.15.7
deb_cflags = -g
deb_cxxflags = -g
ifneq (,$(filter noopt,$(DEB_BUILD_OPTIONS)))
DEB_OPT_FLAG ?= -O0
else
DEB_OPT_FLAG ?= -O2
endif
deb_cflags += $(DEB_OPT_FLAG)
deb_cxxflags += $(DEB_OPT_FLAG)
endif

DEB_WARNING_FLAGS ?= -Wall
deb_cflags += $(DEB_WARNING_FLAGS)
deb_cxxflags += $(DEB_WARNING_FLAGS)

# This variable was deprecated after cdbs 0.4.89
_cdbs_deprecated_vars += DEB_OPT_FLAG
_cdbs_deprecated_DEB_OPT_FLAG_default := $(DEB_OPT_FLAG)

# Set (not add) our defaults for CFLAGS CPPFLAGS CXXFLAGS and LDFLAGS if
# undefined or defined implicitly by make (i.e. if not set or set empty)
deb_cflags_nondefault := $(call cdbs_expand_nondefaultvar,CFLAGS,$(deb_cflags))
deb_cppflags_nondefault := $(call cdbs_expand_nondefaultvar,CPPFLAGS,$(deb_cppflags))
deb_cxxflags_nondefault := $(call cdbs_expand_nondefaultvar,CXXFLAGS,$(deb_cxxflags))
deb_fflags_nondefault := $(call cdbs_expand_nondefaultvar,FFLAGS,$(deb_fflags))
deb_ldflags_nondefault := $(call cdbs_expand_nondefaultvar,LDFLAGS,$(deb_ldflags))
CFLAGS ?= $(deb_cflags_nondefault)
CPPFLAGS ?= $(deb_cppflags_nondefault)
CXXFLAGS ?= $(deb_cxxflags_nondefault)
FFLAGS ?= $(deb_fflags_nondefault)
LDFLAGS ?= $(deb_ldflags_nondefault)

ifneq (,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
	DEB_PARALLEL_JOBS ?= $(patsubst parallel=%,%,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
endif

endif
