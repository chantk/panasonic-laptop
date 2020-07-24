#ifndef PANASONIC_LAPTOP
# This part runs as a normal, top-level Makefile:
X:=$(shell false)
KVER        := $(shell uname -r)
KBASE       := /lib/modules/$(KVER)
KSRC        := $(KBASE)/source
KBUILD      := $(KBASE)/build
MOD_DIR     := $(KBASE)/kernel
PWD         := $(shell pwd)
IDIR        := include/linux
PCC_DIR     := drivers/platform/x86
PANASONIC_LAPTOP := panasonic-laptop.o
SHELL       := /bin/bash

DEBUG := 0

.PHONY: default clean modules load unload install patch 
export PANASONIC_LAPTOP

#####################################################################
# Main targets

default: modules

# Build the modules panasonic-laptop.ko
modules:
	$(MAKE) $(EXTRA_CFLAGS) -C $(KBUILD) M=$(PWD) O=$(KBUILD)

clean:
	rm -f panasonic-laptop.mod.* panasonic-laptop.o panasonic-laptop.ko .panasonic-laptop.*.cmd
	rm -f *~ diff/*~ *.orig diff/*.orig *.rej diff/*.rej
	rm -fr .tmp_versions Modules.symvers

load: unload modules
	@( [ `id -u` == 0 ] || { echo "Must be root to load modules"; exit 1; } )
	modprobe panasonic_laptop
	@echo -e '\nRecent dmesg output:' ; dmesg | tail -10

unload:
	@( [ `id -u` == 0 ] || { echo "Must be root to unload modules"; exit 1; } )
	if `lsmod | grep -q '^panasonic[-_]laptop '` ; then modprobe -r panasonic-laptop; fi

install: modules
	@( [ `id -u` == 0 ] || { echo "Must be root to install modules"; exit 1; } )
	rm -f $(MOD_DIR)/$(PCC_DIR)/panasonic-laptop.ko
	rm -f $(MOD_DIR)/drivers/firmware/panasonic-laptop.ko
	rm -f $(MOD_DIR)/extra/panasonic-laptop.ko
	install -m 0644 $(PWD)/panasonic-laptop.ko $(MOD_DIR)/$(PCC_DIR)
	depmod -a


#####################################################################
# Generate a stand-alone kernel patch

# PCC_VER := ${shell sed -ne 's/^\#define PCC_VERSION \"\(.*\)\"/\1/gp' tp_smapi.c}
# ORG    := a
# NEW    := b
# PATCH  := panasonic-laptop-$(PCC_VER)-for-$(KVER).patch
#
#BASE_IN_PATCH  := 1
#
#patch: $(KSRC)
#	@TMPDIR=`mktemp -d /tmp/panasonic-laptop-patch.XXXXXX` &&\
#	echo "Working directory: $$TMPDIR" &&\
#	cd $$TMPDIR &&\
#	mkdir -p $(ORG)/$(PCC_DIR) &&\
#	mkdir -p $(ORG)/$(IDIR) &&\
#	cp $(KSRC)/$(PCC_DIR)/{Kconfig,Makefile} $(ORG)/$(PCC_DIR) &&\
#	cp -r $(ORG) $(NEW) &&\
#	\
#	if [ "$(BASE_IN_PATCH)" == 1 ]; then \
#		cp $(PWD)/panasonic-laptop.c $(NEW)/$(PCC_DIR)/panasonic-laptop.c &&\
#		cp $(PWD)/panasonic-laptop.h $(NEW)/$(IDIR)/panasonic-laptop.h &&\
#		perl -i -pe 'print `cat $(PWD)/diff/Kconfig-panasonic-laptop.add` if m/^(endmenu|endif # MISC_DEVICES)$$/' $(NEW)/$(PCC_DIR)/Kconfig &&\
#		sed -i -e '$$aobj-$$(CONFIG_THINKPAD_EC)       += panasonic-laptop.o' $(NEW)/$(PCC_DIR)/Makefile \
#	; fi &&\
#	\
#	{ diff -dNurp $(ORG) $(NEW) > patch \
#	  || [ $$? -lt 2 ]; } &&\
#	{ echo "Generated for $(KVER) in $(KSRC)"; echo; diffstat patch; echo; echo; cat patch; } \
#	  > $(PWD)/${PATCH} &&\
#	rm -r $$TMPDIR
#	@echo
#	@diffstat ${PATCH}
#	@echo -e "\nPatch file created:\n  ${PATCH}"
#	@echo -e "To apply, use:\n  patch -p1 -d ${KSRC} < ${PATCH}"
#
######################################################################
## Tools for preparing a release. Ignore these.
#
#set-version:
#	perl -i -pe 's/^(panasonic-laptop version ).*/$${1}$(VER)/' README
#	perl -i -pe 's/^(#define PCC_VERSION ").*/$${1}$(VER)"/' panasonic-laptop.c
#
#TGZ=../panasonic-laptop-$(VER).tgz
#create-tgz:
#	git archive  --format=tar --prefix=panasonic-laptop-$(VER)/ HEAD | gzip -c > $(TGZ)
#	tar tzvf $(TGZ)
#	echo "Ready: $(TGZ)"
#
#else
######################################################################
## This part runs as a submake in kernel Makefile context:

EXTRA_CFLAGS := $(CFLAGS) -I$(M)/include -I$(KSRC)/$(IDIR)
obj-m        := $(PANASONIC_LAPTOP)

ccflags-y    := -I$(M)/include
ccflags-y    += -I$(KSRC)/$(IDIR)

#endif
