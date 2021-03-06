# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2002 Colin Walters <walters@debian.org>
# Description: A class to fix docbook DTD references
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

ifndef _cdbs_class_docbookxml
_cdbs_class_docbookxml = 1

include $(_cdbs_rules_path)/buildcore.mk$(_cdbs_makefile_suffix)

# This class does nothing now that docbook works in Debian sid.

endif
