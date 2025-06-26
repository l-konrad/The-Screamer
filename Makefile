# Proxy Makefile to allow easier call to the nuttx directory
MAKECMDGOALS ?= all
.PHONY: $(MAKECMDGOALS)
$(MAKECMDGOALS):
	+make -C nuttx $(MAKEARGS) $@
