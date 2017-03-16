# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Stefan Gybas <sgybas@debian.org>
# Description: Defines useful variables for packages which use Ant
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

ifndef _cdbs_class_ant_vars
_cdbs_class_ant_vars = 1

# Ant home directory.  Doesn't need to be changed except when using
# nonstandard Ant installations.
ANT_HOME ?= /usr/share/ant

# The home directory of the Java Runtime Environment (JRE) or Java Development
# Kit (JDK). You can either directly set JAVA_HOME in debian/rules or set
# JAVA_HOME_DIRS to multiple possible home directories. The first existing
# directory from this list is used for JAVA_HOME. You can also override
# JAVACMD in case you don't want to use the default JAVA_HOME/bin/java.
JAVA_HOME ?= $(shell for jh in $(JAVA_HOME_DIRS); do if [ -x "$$jh/bin/java" ]; then \
	    echo $${jh}; exit 0; fi; done)
JAVACMD ?= $(JAVA_HOME)/bin/java

# You can list all Java ARchives (JARs) to be added to the class path in
# DEB_JARS, either with their full path or just the basename if the JAR is
# in /usr/share/java. You may also ommit the ".jar" extension. Non-existing
# files will silently be ignored. tools.jar is automatically added to the
# end of the class path if it exists in the JDK's lib directory.
# You can override the complete class path using DEB_CLASSPATH.
DEB_JARS_BASE ?= /usr/share/java
DEB_CLASSPATH ?= $(ANT_HOME)/lib/ant.jar:$(ANT_HOME)/lib/ant-launcher.jar:$(shell for jar in $(DEB_JARS); do \
		if [ -f "$$jar" ]; then echo -n "$${jar}:"; fi; \
		if [ -f "$$jar".jar ]; then echo -n "$${jar}.jar:"; fi; \
		if [ -f $(DEB_JARS_BASE)/"$$jar" ]; then echo -n "$(DEB_JARS_BASE)/$${jar}:"; fi; \
		if [ -f $(DEB_JARS_BASE)/"$$jar".jar ]; then echo -n "$(DEB_JARS_BASE)/$${jar}.jar:"; fi; \
		done; \
		if [ -f "$(JAVA_HOME)/lib/tools.jar" ]; then echo -n "$(JAVA_HOME)/lib/tools.jar"; fi)

# Set compile.debug and compile.optimize depending on DEB_BUILD_OPTIONS to
# match the behaviour of C/C++ programs
DEB_ANT_ARGS ?= -Dcompile.debug=true
ifneq (,$(filter noopt,$(DEB_BUILD_OPTIONS)))
	DEB_ANT_ARGS += -Dcompile.optimize=false
else
	DEB_ANT_ARGS += -Dcompile.optimize=true
endif

# Property file for Ant, defaults to debian/ant.properties if it exists.
# You may define additional properties that are referenced from build.xml so
# you don't have to modify upstream's build.xml. Please note that command-line
# arguments in ANT_ARGS (see below) override the settings in build.xml and
# the property file.
DEB_ANT_PROPERTYFILE ?= $(shell test -f $(CURDIR)/debian/ant.properties && echo $(CURDIR)/debian/ant.properties)

# You can specify additional JVM arguments in ANT_OPTS and Ant command-line
# arguments in ANT_ARGS, like for the Ant wrapper script and sepcified in
# Ant's documentation ("Running Ant"). You can additionally define
# ANT_ARGS_<package> for each individual package, e.g. to override the default
# settings for compile.optimize.
DEB_ANT_INVOKE ?= cd $(DEB_BUILDDIR) && $(JAVACMD) -classpath $(DEB_CLASSPATH) \
		 $(ANT_OPTS) -Dant.home=$(ANT_HOME) \
		 org.apache.tools.ant.Main $(DEB_ANT_ARGS) \
		 $(if $(ANT_ARGS_$(cdbs_curpkg)),$(ANT_ARGS_$(cdbs_curpkg)),$(ANT_ARGS)) \
		 $(if $(DEB_ANT_COMPILER),-Dbuild.compiler=$(DEB_ANT_COMPILER),) \
		 $(if $(DEB_ANT_BUILDFILE),-buildfile $(DEB_ANT_BUILDFILE),) \
		 $(if $(DEB_ANT_PROPERTYFILE),-propertyfile $(DEB_ANT_PROPERTYFILE),)

# Targets to invoke for building, installing, testing and cleaning up.
# Building uses the default target from build.xml, installing and testing is
# only called if the corresponding variable is set. You can also specify
# multiple targets for each step.
#DEB_ANT_BUILD_TARGET =
#DEB_ANT_INSTALL_TARGET =
#DEB_ANT_CHECK_TARGET =
DEB_ANT_CLEAN_TARGET ?= clean

endif
