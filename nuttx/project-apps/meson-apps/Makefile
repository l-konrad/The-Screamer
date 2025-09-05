include $(APPDIR)/Make.defs

all:: .built
	@
.PHONY: clean depend distclean

preconfig::
	@

context:: build/build.ninja

depend::
	@:

install::
	@:

postinstall::
	@:

clean::
	$(call CLEAN)
	$(call DELFILE, libsyms)
	$(Q) [ ! -f build/build.ninja ] || ninja -C build clean

distclean::
	$(call DELFILE, crossfile.ini Toolchain.cmake)
	$(call DELFILE, build.ninja.mk)
	$(call DELFILE, libsyms)
	$(call RMDIR, build)

.FORCE:
crossfile.ini: .FORCE
	$(Q) bash crossfile.sh '$(CC)' '$(CXX)' '$(AR)' '$(STRIP)' '$(CFLAGS)' '$(CXXFLAGS)'

.PRECIOUS: build/build.ninja
# Note: The build.ninja.mk is also provided by this but it must not be mentioned
# here because it would trigger meson setup too early.
build/build.ninja: crossfile.ini meson-setup.sh
	$(Q) bash meson-setup.sh


DEFAULT_PRIORITY  = $(CONFIG_MESON_APPS_DEFAULT_PRIORITY)
DEFAULT_STACKSIZE = $(CONFIG_MESON_APPS_DEFAULT_STACKSIZE)

CONFIG = $(shell fq -r '."$(1)".$(2) // $(3)' config.toml)
PRIORITY = $(call CONFIG,$(1),priority,"$$(DEFAULT_PRIORITY)")
STACKSIZE = $(call CONFIG,$(1),stacksize,"$$(DEFAULT_STACKSIZE)")

define NINJA_TARGET

.NOTPARALLEL: build/$(1)
build/$(1): build/build.ninja .FORCE
	$$(ECHO_BEGIN)"NINJA: $(1) "
	$$(Q) flock build ninja $$(if $$(V),,--quiet) -C build $(1)
	$$(ECHO_END)

endef

# Static library installed from Meson
# $(1): meson target name
define STATIC_LIBRARY

BUILDS += build/$(1).built
LIBRARIES += build/$(1)

build/$(1).built: build/$(1)
	$$(ECHO_BEGIN)"AR: $(1) "
	$$(Q) mkdir -p build/$(1).a
	$$(Q) $$(UNAR) --output build/$(1).a build/$(1)
	$$(Q) cd build/$(1).a && for f in *.o; do mv "$$$$f" "$(subst $(DELIM),.,$(1))_$$f"; done
	$$(Q) $$(call ARLOCK, $$(call CONVERT_PATH,$$(BIN)), build/$(1).a/*)
	$$(Q) $$(call DELDIR, build/$(1).a)
	$$(Q) touch $$@
	$$(ECHO_END)

$(call NINJA_TARGET,$(1))

endef

# Executable installed from Meson
# $(1): meson target name
# $(2): application name
# $(3): application main name
define EXECUTABLE

register:: $$(BUILTIN_REGISTRY)$$(DELIM)$(2).bdat
$$(BUILTIN_REGISTRY)$$(DELIM)$(2).bdat: build/build.ninja config.toml
	$$(call REGISTER,$(2),$(call PRIORITY,$(2)),$(call STACKSIZE,$(2)),$$(if $$(BUILD_MODULE),,$(3)))

BUILDS += build/$(1).built

build/$(1).built: build/$(1) libsyms
	$$(ECHO_BEGIN)"AR: $(1) "
	$$(Q) $$(CROSSDEV)nm --just-symbols --defined-only build/$(1) \
		| sort -u | comm -2 - libsyms >build/$(1).syms
	$$(Q) $$(CROSSDEV)objcopy \
		--redefine-sym main=$(3) \
		$$$$([[ -s build/$(1).syms ]] && printf '%s' '--localize-symbols=build/$(1).syms') \
		$$$$([[ -s libsyms ]] && printf '%s' '--weaken-symbols=libsyms') \
		build/$(1) build/$(1).o
	$$(Q) $$(call ARLOCK, $$(call CONVERT_PATH,$$(BIN)), build/$(1).o)
	$$(Q) touch $$@
	$$(ECHO_END)

$(call NINJA_TARGET,$(1))

endef

-include build.ninja.mk


libsyms: $(LIBRARIES)
	$(Q) $(if $^,$(CROSSDEV)nm --just-symbols --defined-only $^ | sort -u > $@,touch $@)

.built: build.ninja.mk $(BUILDS)
	$(Q) touch $@
