# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Colin Walters <walters@debian.org>
# Copyright © 2005-2012 Jonas Smedegaard <dr@jones.dk>
# Description: Defines various random rules, including a list-missing rule
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

ifndef _cdbs_rules_utils
_cdbs_rules_utils = 1

include $(_cdbs_rules_path)/buildcore.mk$(_cdbs_makefile_suffix)

# Routines convenient for maintainers but unsuitable for build daemons
#  * strict checking makes rule fail if changed/new hints are found
ifneq (,$(DEB_MAINTAINER_MODE))
  DEB_COPYRIGHT_CHECK_STRICT ?= yes
endif

# Single regular expression for files to include or ignore
DEB_COPYRIGHT_CHECK_REGEX ?= .*
DEB_COPYRIGHT_CHECK_IGNORE_REGEX ?= ^debian/(changelog|copyright(|_hints|_newhints))$

# number of lines from the top of each file to investigate
DEB_COPYRIGHT_CHECK_PARSELINES ?= 99999

DEB_COPYRIGHT_CHECK_SCRIPT ?= licensecheck
DEB_COPYRIGHT_CHECK_ARGS ?= -c '$(DEB_COPYRIGHT_CHECK_REGEX)' -r --copyright -i '$(DEB_COPYRIGHT_CHECK_IGNORE_REGEX)' -l '$(DEB_COPYRIGHT_CHECK_PARSELINES)' *
DEB_COPYRIGHT_CHECK_INVOKE ?= $(DEB_COPYRIGHT_CHECK_SCRIPT) $(DEB_COPYRIGHT_CHECK_ARGS)

# spacing between multiline file and copyright items
DEB_COPYRIGHT_CHECK_DELIMITER ?= $(subst $(comma),,$(CDBS_BUILD_DEPENDS_DELIMITER))

# Space-delimited lists of directories and files to move or copy aside
# DEB_UPSTREAM_CRUFT_MOVE =
# DEB_UPSTREAM_CRUFT_COPY =

# location for backup of upstream files and directories
DEB_UPSTREAM_CRUFT_BACKUPDIR ?= debian/upstream-cruft

DEB_PHONY_RULES += list-missing

CDBS_BUILD_DEPENDS_rules_utils_copyright-check ?= devscripts
CDBS_BUILD_DEPENDS += , $(CDBS_BUILD_DEPENDS_rules_utils_copyright-check)

CDBS_BUILD_DEPENDS_rules_utils_upstream_cruft ?= cdbs (>= 0.4.106~)
CDBS_BUILD_DEPENDS += , $(if $(DEB_UPSTREAM_CRUFT_MOVE)$(DEB_UPSTREAM_CRUFT_COPY),$(CDBS_BUILD_DEPENDS_rules_utils_upstream_cruft))

list-missing:
	@if test -d debian/tmp; then \
	  (cd debian/tmp && find . -type f -o -type l | grep -v '/DEBIAN/' | sort) > debian/cdbs-install-list; \
	  (for package in $(DEB_ALL_PACKAGES); do \
	     (cd debian/$$package && find . -type f -o -type l); \
	   done; \
	   test -e debian/not-installed && grep -v '^#' debian/not-installed; \
	   ) | sort -u > debian/cdbs-package-list; \
          echo "# list-missing files result:"; \
	  diff -u debian/cdbs-install-list debian/cdbs-package-list | sed '1,2d' | egrep '^-' || true; \
	else \
	  echo "All files were installed into debian/$(DEB_SOURCE_PACKAGE)."; \
	fi

pre-build:: debian/stamp-copyright-check
debian/stamp-copyright-check:
	@set -e; if [ ! -f debian/copyright_hints ]; then \
		echo; \
		echo '$(if $(DEB_COPYRIGHT_CHECK_STRICT),ERROR,WARNING): copyright-check disabled - touch debian/copyright_hints to enable.'; \
		echo; \
		$(if $(DEB_COPYRIGHT_CHECK_STRICT),exit 1,:); \
	elif [ licensecheck = $(DEB_COPYRIGHT_CHECK_SCRIPT) ] && ! which licensecheck > /dev/null; then \
		echo; \
		echo '$(if $(DEB_COPYRIGHT_CHECK_STRICT),ERROR,WARNING): copyright-check disabled - licensecheck (from devscripts package) is missing.'; \
		echo; \
		$(if $(DEB_COPYRIGHT_CHECK_STRICT),exit 1,:); \
	elif [ licensecheck = $(DEB_COPYRIGHT_CHECK_SCRIPT) ] && ! licensecheck --help | grep -qv -- --copyright; then \
		echo; \
		echo '$(if $(DEB_COPYRIGHT_CHECK_STRICT),ERROR,WARNING): copyright-check disabled - licensecheck (from devscripts package) seems older than needed 2.10.7.'; \
		echo; \
		$(if $(DEB_COPYRIGHT_CHECK_STRICT),exit 1,:); \
	else \
		echo; \
		echo 'Scanning upstream source for new/changed copyright notices...'; \
		echo; \
		echo "$(DEB_COPYRIGHT_CHECK_INVOKE) | $(_cdbs_scripts_path)/licensecheck2dep5 > debian/copyright_newhints"; \
		export LC_ALL=C; \
		export whitespace_list_delimiter="`perl -e 'print "$(DEB_COPYRIGHT_CHECK_DELIMITER)"'`"; \
		export merge_same_license="$(DEB_COPYRIGHT_CHECK_MERGE_SAME_LICENSE)"; \
		$(DEB_COPYRIGHT_CHECK_INVOKE) | $(_cdbs_scripts_path)/licensecheck2dep5 > debian/copyright_newhints; \
		echo "`grep -c ^Files: debian/copyright_hints` combinations of copyright and licensing found."; \
		newstrings=`diff -a -u debian/copyright_hints debian/copyright_newhints | sed '1,2d' | egrep -a '^\+' - | sed 's/^\+//'`; \
		if [ -n "$$newstrings" ]; then \
			echo "$(if $(DEB_COPYRIGHT_CHECK_STRICT),ERROR,WARNING): The following (and possibly more) new or changed notices discovered:"; \
			echo; \
			echo "$$newstrings" \
				| perl -ne '/^.{0,60}$$/ or s/^(.{0,60})\b.*$$/$$1…/;s/[^[:print:][:space:]…]//g;$$_ ne $$prev and (($$prev) = $$_) and print' \
				| sort -m \
				| head -n 200; \
			echo; \
			echo "To fix the situation please do the following:"; \
			echo "  1) Fully compare debian/copyright_hints with debian/copyright_newhints"; \
			echo "  2) Update debian/copyright as needed"; \
			echo "  3) Replace debian/copyright_hints with debian/copyright_newhints"; \
			$(if $(DEB_COPYRIGHT_CHECK_STRICT),exit 1,:); \
		else \
			echo 'No new copyright notices found - assuming no news is good news...'; \
			rm -f debian/copyright_newhints; \
		fi; \
	fi
	touch $@

clean::
	$(if $(DEB_COPYRIGHT_CHECK_STRICT),,rm -f debian/copyright_newhints)
	rm -f debian/cdbs-install-list debian/cdbs-package-list debian/stamp-copyright-check

# put aside upstream cruft during build but after copyright-check
pre-build:: debian/stamp-upstream-cruft
debian/stamp-upstream-cruft: debian/stamp-copyright-check
	$(and $(DEB_UPSTREAM_CRUFT_MOVE)$(DEB_UPSTREAM_CRUFT_COPY),mkdir -p "$(DEB_UPSTREAM_CRUFT_BACKUPDIR)")
	@for orig in $(DEB_UPSTREAM_CRUFT_MOVE); do \
		backup="$(DEB_UPSTREAM_CRUFT_BACKUPDIR)/$$orig"; \
		[ ! -e "$$orig" ] || [ -e "$$backup" ] || { \
			mkdir -p "$$(dirname "$$backup")"; \
			echo mv "$$orig" "$$backup"; \
			mv "$$orig" "$$backup"; \
		}; \
	done
	@for orig in $(DEB_UPSTREAM_CRUFT_COPY); do \
		backup="$(DEB_UPSTREAM_CRUFT_BACKUPDIR)/$$orig"; \
		[ ! -e "$$orig" ] || [ -e "$$backup" ] || { \
			mkdir -p "$$(dirname "$$backup")"; \
			echo "cp -a" "$$orig" "$$backup"; \
			cp -a "$$orig" "$$backup"; \
		}; \
	done
	touch $@
clean::
	@for orig in $(DEB_UPSTREAM_CRUFT_MOVE) $(DEB_UPSTREAM_CRUFT_COPY); do \
		backup="$(DEB_UPSTREAM_CRUFT_BACKUPDIR)/$$orig"; \
		if [ -e "$$backup" ]; then \
			if [ -e "$$orig" ]; then \
				echo "rm -rf" "$$orig"; \
				rm -rf "$$orig"; \
			fi; \
			echo mv "$$backup" "$$orig"; \
			mv "$$backup" "$$orig"; \
		fi; \
	done
	rm -rf "$(DEB_UPSTREAM_CRUFT_BACKUPDIR)"
	rm -f debian/stamp-upstream-cruft

endif
