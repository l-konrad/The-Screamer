MAKEFLAGS += --no-builtin-rules

.PHONY: all
all: build

.PHONY: help
help:
	@echo 'Top level targets:'
	@echo '  build: Compile the NuttX'
	@echo '  run: Run NuttX in Qemu'
	@echo '  menuconfig: Open the configuration menu'
	@echo '  nuttx/menuconfig: Open the configuration menu for NuttX'
	@echo '  clean: Remove build files for the NuttX'
	@echo '  distclean: Remove any generated files in the NuttX'
	@echo '  gitclean: Remove files that are not tracked by git'

ifneq ($(if $(MAKECMDGOALS),$(filter-out help clean distclean,$(MAKECMDGOALS)),all),)
  -include .config
  -include .dependencies.mk
endif

NUTTXGOALS = $(filter nuttx/%,$(MAKECMDGOALS))
.PHONY: build $(NUTTXGOALS)
build: core/nuttx

CONFIG_CROSSDEV ?= riscv32-none-elf-
CROSSDEV ?= $(CONFIG_CROSSDEV)

NUTTX_ARGS += CROSSDEV=$(CROSSDEV)
ifneq ($(shell command -v git),)
NUTTX_ARGS += VERSION_ARG="-b '$(shell ../.version.sh nuttx)'"
else
NUTTX_ARGS += VERSION_ARG="-b '$(shell ../.version.sh nuttx)' -v '$(file <.version)'"
endif

## NuttX configuration and target proxy ########################################

core/.config: tools/nuttx-config.sh .config
	MAKE='$(MAKE)' bash tools/nuttx-config.sh

.PHONY: .FORCE
.FORCE:
core/%: .FORCE
	+make -C core $(MAKEARGS) $(NUTTX_ARGS) $*

# NuttX required configuration for all targets except of cleanup goals
define XNUTTXCONF
$(1): core/.config
endef
COREGOALS = core/nuttx $(filter core/%,$(MAKECMDGOALS)) $(patsubst nuttx/%,core/%,$(NUTTXGOALS))
$(foreach X,$(filter-out core/.config core/%clean,$(COREGOALS) core/nuttx),$(eval $(call XNUTTXCONF,$(X))))

# nuttx alias for core
define XNUTTXCORE
$(1): $(patsubst nuttx/%,core/%,$(1))
endef
$(foreach X,$(NUTTXGOALS),$(eval $(call XNUTTXCORE,$(X))))

## Runing in Qemu ##############################################################

run: core/nuttx
	qemu-system-riscv32 -semihosting -M virt,aclint=on -cpu rv32 -bios none -kernel $< -nographic

## Configuration ###############################################################

.config: Kconfig
	kconfig-conf --olddefconfig Kconfig

define XCONFIG
.PHONY: $(1)
$(1): Kconfig
	$(2) Kconfig
endef
$(eval $(call XCONFIG,config,kconfig-conf))
$(eval $(call XCONFIG,oldconfig,kconfig-conf --oldconfig))
$(eval $(call XCONFIG,olddefconfig,kconfig-conf --olddefconfig))
$(eval $(call XCONFIG,menuconfig,kconfig-mconf))
$(eval $(call XCONFIG,nconfig,kconfig-nconf))
$(eval $(call XCONFIG,qconfig,kconfig-qconf))
$(eval $(call XCONFIG,gconfig,kconfig-gconf))

################################################################################

.dependencies.mk: tools/nuttx-config.sh .config
	bash ./tools/nuttx-config.sh dependencies$(if $(filter y,$(CONFIG_BOOTLOADER)), bootloader) >$@


.PHONY: clean
clean: core/clean
	@

# Note: We have to remove links that lead to external files as distclean won't
# remove them.
.PHONY: distclean
distclean:
	rm -f core/arch/arm/include/board
	rm -f core/arch/arm/include/chips
	rm -f core/arch/arm/src/board
	rm -f board/scripts/flash.ld
	+make -C core $(MAKEARGS) $(NUTTX_ARGS) distclean

.PHONY: gitclean
gitclean:
	git submodule foreach --recursive git clean -xdff
	git clean -xdff project-apps project-libs board
