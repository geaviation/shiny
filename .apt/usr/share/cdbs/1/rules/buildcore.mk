# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2002,2003 Colin Walters <walters@debian.org>
# Copyright © 2009-2011 Jonas Smedegaard <dr@jones.dk>
# Description: Defines the rule framework
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

ifndef _cdbs_rules_buildcore
_cdbs_rules_buildcore = 1

include $(_cdbs_rules_path)/buildvars.mk$(_cdbs_makefile_suffix)

testdir: debian/control
	test -x debian/rules

testroot:
	$(if $(_cdbs_rules_debhelper),dh_testroot,test "`id -u`" = 0)

# These targets are triggered by pre-build and clean targets allowing
# for non-intrusive sanity checks of the build environment
$(patsubst %,testsanity/%,$(DEB_ALL_PACKAGES)) :: testsanity/% : 
testsanity:: $(patsubst %,testsanity/%,$(DEB_ALL_PACKAGES))

$(patsubst %,makebuilddir/%,$(DEB_ALL_PACKAGES)) :: makebuilddir/% : 
	$(if $(DEB_BUILDDIR_$(cdbs_curpkg)),mkdir -p "$(DEB_BUILDDIR_$(cdbs_curpkg))")

makebuilddir:: $(patsubst %,makebuilddir/%,$(DEB_ALL_PACKAGES))
	mkdir -p "$(DEB_BUILDDIR)"

cleanbuilddir:: $(patsubst %,cleanbuilddir/%,$(DEB_ALL_PACKAGES))
	-$(if $(call cdbs_streq,$(DEB_BUILDDIR),$(DEB_SRCDIR)),,rmdir $(DEB_BUILDDIR))

$(patsubst %,cleanbuilddir/%,$(DEB_ALL_PACKAGES)) :: cleanbuilddir/% : 
	-$(if $(DEB_BUILDDIR_$(cdbs_curpkg)),$(if $(call cdbs_streq,$(DEB_BUILDDIR_$(cdbs_curpkg)),$(DEB_SRCDIR)),,rmdir "$(DEB_BUILDDIR_$(cdbs_curpkg))"))


# This variable is used by tarball.mk, but we want it here in order to check
# tarball contents before unpacking.  tarball.mk imports this file anyway.
DEB_TARBALL ?= $(wildcard *.tar *.tgz *.tar.gz *.tar.bz *.tar.bz2 *.tar.lzma *.zip)

CDBS_BUILD_DEPENDS_rules_buildcore_bz2 ?= bzip2
CDBS_BUILD_DEPENDS += $(if $(findstring .bz2,$(DEB_TARBALL)),$(comma) $(CDBS_BUILD_DEPENDS_rules_buildcore_bz2))

CDBS_BUILD_DEPENDS_rules_buildcore_zip ?= unzip
CDBS_BUILD_DEPENDS += $(if $(findstring .zip,$(DEB_TARBALL)),$(comma) $(CDBS_BUILD_DEPENDS_rules_buildcore_zip))

ifneq (, $(DEB_TARBALL))
$(warning parsing $(DEB_TARBALL) ...)
config_all_tar		:= $(shell \
for i in $(DEB_TARBALL) ; do \
	if ! test -e $$i.cdbs-config_list ; then \
		echo Parsing $$i... >&2 ; \
		case $$i in \
			*.tar$(close_parenthesis) tar -tf $$i | grep "/config\.[^/]*$$" > $$i.cdbs-config_list ;; \
			*.tgz|*.tar.gz$(close_parenthesis) tar -tzf $$i | grep "/config\.[^/]*$$" > $$i.cdbs-config_list ;; \
			*.tar.bz|*.tar.bz2$(close_parenthesis) tar -tjf $$i | grep "/config\.[^/]*$$" > $$i.cdbs-config_list ;; \
			*.tar.lzma$(close_parenthesis) tar -t --lzma -f $$i | grep "/config\.[^/]*$$" > $$i.cdbs-config_list ;; \
			*.zip$(close_parenthesis) unzip -l $$i | grep "/config\.[^/]*$$" > $$i.cdbs-config_list ;; \
			*$(close_parenthesis) echo Warning: tarball $$i with unknown format >&2 ;; \
		esac ; \
	fi ; \
	cat $$i.cdbs-config_list ; \
done)
endif

# Avoid recursive braindamage if we're building autotools-dev
ifeq (, $(shell grep -x 'Package: autotools-dev' debian/control))
config_guess		:= $(shell find $(DEB_SRCDIR) \( -type f -or -type l \) -name config.guess)
config_sub		:= $(shell find $(DEB_SRCDIR) \( -type f -or -type l \) -name config.sub)
ifneq (, $(config_all_tar))
config_guess_tar	:= $(filter %/config.guess, $(config_all_tar))
config_sub_tar		:= $(filter %/config.sub, $(config_all_tar))
endif
endif
# Ditto for gnulib
ifeq (, $(shell grep -x 'Package: gnulib' debian/control))
config_rpath		:= $(shell find $(DEB_SRCDIR) \( -type f -or -type l \) -name config.rpath)
ifneq (, $(config_all_tar))
config_rpath_tar	:= $(filter %/config.rpath, $(config_all_tar))
endif
endif

CDBS_BUILD_DEPENDS_rules_buildcore_config-guess-sub ?= autotools-dev
CDBS_BUILD_DEPENDS += $(if $(config_guess)$(config_sub)$(config_guess_tar)$(config_sub_tar),$(comma) $(CDBS_BUILD_DEPENDS_rules_buildcore_config-guess-sub))

CDBS_BUILD_DEPENDS_rules_buildcore_config-rpath ?= gnulib
CDBS_BUILD_DEPENDS += $(if $(config_rpath)$(config_rpath_tar),$(comma) $(CDBS_BUILD_DEPENDS_rules_buildcore_config-rpath))

# This target is called before almost anything else happens.  It's a good place
# to do stuff like unpack extra source tarballs, apply patches, and stuff.  In
# the future it will be a good place to generate debian/control, but right
# now we don't support that very well.
pre-build:: testdir testsanity makebuilddir
	$(foreach x,$(_cdbs_deprecated_vars),$(if $(shell test "$($x)" != "$(_cdbs_deprecated_$(x)_default)" && echo W),$(warning WARNING:  $x is a deprecated variable)))

# This target is called after patches are applied.  Used by the patch system.
post-patches:: pre-build apply-patches update-config
update-config::
ifneq (, $(config_guess))
	if test -e /usr/share/misc/config.guess ; then \
		for i in $(config_guess) ; do \
			if ! test -e $$i.cdbs-orig ; then \
				mv $$i $$i.cdbs-orig ; \
				cp --remove-destination /usr/share/misc/config.guess $$i ; \
			fi ; \
		done ; \
	fi
endif
ifneq (, $(config_sub))
	if test -e /usr/share/misc/config.sub ; then \
		for i in $(config_sub) ; do \
			if ! test -e $$i.cdbs-orig ; then \
				mv $$i $$i.cdbs-orig ; \
				cp --remove-destination /usr/share/misc/config.sub $$i ; \
			fi ; \
		done ; \
	fi
endif
ifneq (, $(config_rpath))
	if test -e /usr/share/gnulib/build-aux/config.rpath ; then \
		for i in $(config_rpath) ; do \
			if ! test -e $$i.cdbs-orig ; then \
				mv $$i $$i.cdbs-orig ; \
				cp --remove-destination /usr/share/gnulib/build-aux/config.rpath $$i ; \
			fi ; \
		done ; \
	fi
endif

# This target should be used to configure the package before building.  Typically
# this involves running things like ./configure.
common-configure-arch:: post-patches
common-configure-indep:: post-patches
$(patsubst %,configure/%,$(DEB_ARCH_PACKAGES)) :: configure/% : common-configure-arch
$(patsubst %,configure/%,$(DEB_INDEP_PACKAGES)) :: configure/% : common-configure-indep

# This is a required Debian target; however, its specific semantics is
# in dispute.  We are of the opinion that 'build' should invoke
# build-arch and build-indep.  Policy tends to support us here.
# However, dpkg-buildpackage is currently invokes debian/rules build
# even when doing an architecture-specific (binary-arch) build.  This
# essentially means Build-Depends-Indep is worthless.  For more
# information, see Policy §5.2, Policy §7.6, and Debian Bug #178809.
# For now, you may override the dependencies by setting the variable
# DEB_BUILD_DEPENDENCIES, below.  This is not recommended.
DEB_BUILD_DEPENDENCIES ?= build-arch build-indep
build: $(DEB_BUILD_DEPENDENCIES)

# This target should take care of actually compiling the package from source.
# Most often this involves invoking "make".
common-build-arch:: testdir $(patsubst %,configure/%,$(DEB_ARCH_PACKAGES))
common-build-indep:: testdir $(patsubst %,configure/%,$(DEB_INDEP_PACKAGES))
$(patsubst %,build/%,$(DEB_ARCH_PACKAGES)) :: build/% : common-build-arch configure/%
$(patsubst %,build/%,$(DEB_INDEP_PACKAGES)) :: build/% : common-build-indep configure/%

# This rule is for stuff to run after the build process.  Note that this
# may run under fakeroot or sudo, so it's inappropriate for things that
# should be run under the build target.
common-post-build-arch:: common-build-arch $(patsubst %,build/%,$(DEB_ARCH_PACKAGES)) 
common-post-build-indep:: common-build-indep $(patsubst %,build/%,$(DEB_INDEP_PACKAGES)) 

# Required Debian targets.
build-arch: $(patsubst %,build/%,$(DEB_ARCH_PACKAGES))
build-indep: $(patsubst %,build/%,$(DEB_INDEP_PACKAGES))

# This rule is used to prepare the source package before a diff is generated.
# Typically you will invoke upstream's "make clean" rule here, although you
# can also hook in other stuff here.  Many of the included rules and classes
# add stuff to this rule.
clean:: testdir cleanbuilddir reverse-config testsanity
reverse-config::
ifneq (::, $(config_guess):$(config_sub):$(config_rpath))
	for i in $(config_guess) $(config_sub) $(config_rpath) ; do \
		if test -e $$i.cdbs-orig ; then \
			mv $$i.cdbs-orig $$i ; \
		fi ; \
	done
endif

# Routines convenient for maintainers but unsuitable for build daemons
ifneq (,$(DEB_MAINTAINER_MODE))
  DEB_AUTO_UPDATE_DEBIAN_CONTROL ?= yes
endif

# Style of separating build-dependencies. Perl-style: tab=\t, newline=\n
#  * Default follows recommended multiline style (see Debian Policy §7.1)
#  * Unset to get recomended single-line style ", "
CDBS_BUILD_DEPENDS_DELIMITER ?= ,\n$(space)

cdbs_re_squash_extended_space = s/[ \t\n]+/ /g
cdbs_re_pkg_strip_versioned_before_sameversioned = s/(?:(?<=\A)|(?<=,)) *([a-z0-9][a-z0-9+\-.]+) *(\([^$(close_parenthesis)]+\)) *,(?=(?:[^,]*,)*? *\1 *\2(?:,|\Z))//g
cdbs_re_pkg_strip_unversioned_before_maybeversioned = s/(?:(?<=\A)|(?<=,)) *([a-z0-9][a-z0-9+\-.]+) *,(?=(?:[^,]*,)*? *\1 *(?:[\$(open_parenthesis),]|\Z))//g
cdbs_re_pkg_strip_unversioned_after_versioned = s/(?:(?<=\A)|(?<=,))( *([a-z0-9][a-z0-9+\-.]+) +\$(open_parenthesis)[^,]+,)((?:[^,]*,)*?) *\2 *(?=,|\Z)/$$1$$3/g
cdbs_re_squash_commas_and_spaces = s/(?:(?<=\A)|(?<=[^, ]))[ ,]*([^,]*?)[ ,]*,(?= ?[^ ,]|\Z)/$$1,/g
cdbs_re_squash_trailing_commas_and_spaces = s/[\s,]*$$//
cdbs_re_wrap_after_commas = s/, */$(or $(CDBS_BUILD_DEPENDS_DELIMITER),$(comma)$(space))/g

cdbs_pkgrel_varnames = $(patsubst %,CDBS_%,DEPENDS PREDEPENDS RECOMMENDS SUGGESTS BREAKS PROVIDES REPLACES CONFLICTS ENHANCES)
cdbs_pkgrel_allvars = $(strip $(call cdbs_expand_allvars,$(cdbs_pkgrel_varnames)))


ifneq (,$(wildcard debian/control.in))
ifneq (,$(DEB_AUTO_UPDATE_DEBIAN_CONTROL))
debian/control::
	@bdep='$(strip $(CDBS_BUILD_DEPENDS))' perl -n \
		-e 'my $$bd = $$ENV{"bdep"};' \
		-e '$$bd =~ $(cdbs_re_squash_extended_space);' \
		-e 'my @matches = $$bd =~ /\bcdbs \(>= 0\.4\.(\d+~?)\)/g;' \
		-e 'my $$max = (sort { $$b <=> $$a } @matches)[0];' \
		-e 'my $$cdbs = $$max ? "cdbs (>= 0.4.$$max)" : @matches ? "cdbs" : "";' \
		-e '$$bd =~ s/\bcdbs \(>= [0-9.~]+\)//g;' \
		-e '$$bd =~ s/^/$$cdbs, /;' \
		-e '$$bd =~ $(cdbs_re_pkg_strip_unversioned_before_maybeversioned);' \
		-e '$$bd =~ $(cdbs_re_pkg_strip_versioned_before_sameversioned);' \
		-e '$$bd =~ $(cdbs_re_pkg_strip_unversioned_after_versioned);' \
		-e '$$bd =~ $(cdbs_re_squash_commas_and_spaces);' \
		-e '$$bd =~ $(cdbs_re_squash_trailing_commas_and_spaces);' \
		-e '$$bd =~ $(cdbs_re_wrap_after_commas);' \
		-e 's/\@cdbs\@/$$bd/g;' \
		-e 's/^Build-Depends(|-Indep): ,/Build-Depends$$1:/g;' \
		\
		-e 'print;' \
	< debian/control.in > debian/control
	-dpkg-checkbuilddeps -B
endif
endif

# This rule is called before the common-install target.  It's currently only
# used by debhelper.mk, to run dh_clean -k.
common-install-prehook-arch::
common-install-prehook-indep::

# This target should do all the work of installing the package into the
# staging directory (debian/packagename or debian/tmp).
common-install-arch:: testdir common-install-prehook-arch common-post-build-arch
common-install-indep:: testdir common-install-prehook-indep common-post-build-indep

# Required Debian targets.
install-arch: $(patsubst %,install/%,$(DEB_ARCH_PACKAGES))
install-indep: $(patsubst %,install/%,$(DEB_INDEP_PACKAGES))

# These rules should do any installation work specific to a particular package.
$(patsubst %,install/%,$(DEB_ARCH_PACKAGES)) :: install/% : testdir testroot common-install-arch build/%
$(patsubst %,install/%,$(DEB_INDEP_PACKAGES)) :: install/% : testdir testroot common-install-indep build/%

# These variables are deprecated.
_cdbs_deprecated_vars += CDBS_DEPENDS CDBS_PREDEPENDS CDBS_RECOMMENDS CDBS_SUGGESTS CDBS_BREAKS CDBS_PROVIDES CDBS_REPLACES CDBS_CONFLICTS CDBS_ENHANCES
# New in 0.4.85.
CDBS_DEPENDS_DEFAULT ?= $(CDBS_DEPENDS)
CDBS_PREDEPENDS_DEFAULT ?= $(CDBS_PREDEPENDS)
CDBS_RECOMMENDS_DEFAULT ?= $(CDBS_RECOMMENDS)
CDBS_SUGGESTS_DEFAULT ?= $(CDBS_SUGGESTS)
CDBS_BREAKS_DEFAULT ?= $(CDBS_BREAKS)
CDBS_PROVIDES_DEFAULT ?= $(CDBS_PROVIDES)
CDBS_REPLACES_DEFAULT ?= $(CDBS_REPLACES)
CDBS_CONFLICTS_DEFAULT ?= $(CDBS_CONFLICTS)
CDBS_ENHANCES_DEFAULT ?= $(CDBS_ENHANCES)

# Apply CDBS-declared dependencies to binary packages
$(patsubst %,install/%,$(DEB_ALL_PACKAGES)) :: install/%:
	@echo 'Adding cdbs dependencies to debian/$(cdbs_curpkg).substvars'
	@echo '$(call cdbs_expand_curvar,CDBS_DEPENDS,$(comma) )'    | perl -0 -ne '$(cdbs_re_squash_extended_space); $(re_squash_commas_and_spaces); /\w/ and print "cdbs:Depends=$$_\n"'     >> debian/$(cdbs_curpkg).substvars
	@echo '$(call cdbs_expand_curvar,CDBS_PREDEPENDS,$(comma) )' | perl -0 -ne '$(cdbs_re_squash_extended_space); $(re_squash_commas_and_spaces); /\w/ and print "cdbs:Pre-Depends=$$_\n"' >> debian/$(cdbs_curpkg).substvars
	@echo '$(call cdbs_expand_curvar,CDBS_RECOMMENDS,$(comma) )' | perl -0 -ne '$(cdbs_re_squash_extended_space); $(re_squash_commas_and_spaces); /\w/ and print "cdbs:Recommends=$$_\n"'  >> debian/$(cdbs_curpkg).substvars
	@echo '$(call cdbs_expand_curvar,CDBS_SUGGESTS,$(comma) )'   | perl -0 -ne '$(cdbs_re_squash_extended_space); $(re_squash_commas_and_spaces); /\w/ and print "cdbs:Suggests=$$_\n"'    >> debian/$(cdbs_curpkg).substvars
	@echo '$(call cdbs_expand_curvar,CDBS_BREAKS,$(comma) )'     | perl -0 -ne '$(cdbs_re_squash_extended_space); $(re_squash_commas_and_spaces); /\w/ and print "cdbs:Breaks=$$_\n"'      >> debian/$(cdbs_curpkg).substvars
	@echo '$(call cdbs_expand_curvar,CDBS_PROVIDES,$(comma) )'   | perl -0 -ne '$(cdbs_re_squash_extended_space); $(re_squash_commas_and_spaces); /\w/ and print "cdbs:Provides=$$_\n"'    >> debian/$(cdbs_curpkg).substvars
	@echo '$(call cdbs_expand_curvar,CDBS_REPLACES,$(comma) )'   | perl -0 -ne '$(cdbs_re_squash_extended_space); $(re_squash_commas_and_spaces); /\w/ and print "cdbs:Replaces=$$_\n"'    >> debian/$(cdbs_curpkg).substvars
	@echo '$(call cdbs_expand_curvar,CDBS_CONFLICTS,$(comma) )'  | perl -0 -ne '$(cdbs_re_squash_extended_space); $(re_squash_commas_and_spaces); /\w/ and print "cdbs:Conflicts=$$_\n"'   >> debian/$(cdbs_curpkg).substvars
	@echo '$(call cdbs_expand_curvar,CDBS_ENHANCES,$(comma) )'   | perl -0 -ne '$(cdbs_re_squash_extended_space); $(re_squash_commas_and_spaces); /\w/ and print "cdbs:Enhances=$$_\n"'    >> debian/$(cdbs_curpkg).substvars

# This rule is called after all packages are installed.
common-binary-arch:: testdir testroot $(patsubst %,install/%,$(DEB_ARCH_PACKAGES))
common-binary-indep:: testdir testroot $(patsubst %,install/%,$(DEB_INDEP_PACKAGES))

# Required Debian targets
binary-indep: $(patsubst %,binary/%,$(DEB_INDEP_PACKAGES))
binary-arch: $(patsubst %,binary/%,$(DEB_ARCH_PACKAGES))

# These rules should do all the work of actually creating a .deb from the staging
# directory.
$(patsubst %,binary/%,$(DEB_ARCH_PACKAGES)) :: binary/% : testdir testroot common-binary-arch install/% 
$(patsubst %,binary/%,$(DEB_INDEP_PACKAGES)) :: binary/% : testdir testroot common-binary-indep install/% 

# Required Debian target
binary: binary-indep binary-arch

##
# Deprecated targets.  You should use the -arch and -indep targets instead.
##
common-configure:: common-configure-arch common-configure-indep 
common-build:: common-build-arch common-build-indep
common-post-build:: common-post-build-arch common-post-build-indep
common-install-prehook:: common-install-prehook-arch common-install-prehook-indep
common-install:: common-install-arch common-install-indep
common-binary:: common-binary-arch common-binary-indep

.PHONY: pre-build testsanity $(patsubst %,testsanity/%,$(DEB_ALL_PACKAGES)) apply-patches post-patches common-configure-arch common-configure-indep $(patsubst %,configure/%,$(DEB_ALL_PACKAGES)) build common-build-arch common-build-indep $(patsubst %,build/%,$(DEB_ALL_PACKAGES)) build-arch build-indep clean common-install-arch common-install-indep install-arch install-indep $(patsubst %,install/%,$(DEB_ALL_PACKAGES)) common-binary-arch common-binary-indep $(patsubst %,binary/%,$(DEB_ALL_PACKAGES)) binary-indep binary-arch binary $(DEB_PHONY_RULES)

# Parallel execution of the cdbs makefile fragments will fail, but
# this way you can call dpkg-buildpackage with MAKEFLAGS=-j in the
# environment and the package's own makefiles can use parallel make.
.NOTPARALLEL:

endif
