# A simple makefile for creating the High Resolution CFD Models bundled product
VERSION    := $(shell git describe --tags --dirty)
PRODUCT    := Process Models Bundle
PROD_SNAME := ProcessModels_bundle
LICENSE    := LICENSE.md
PKG_DIR    := CCSI_$(PROD_SNAME)_$(VERSION)
PACKAGE    := $(PKG_DIR).zip

CATEGORIES := SolidSorbents Solvents OtherModels

TARBALLS := *.tgz
ZIPFILES := *.zip

# The bundled packages, as found in each category subdir
SUB_PACKAGES := $(foreach c,$(CATEGORIES), $(wildcard $c/$(TARBALLS) $c/$(ZIPFILES)))

PAYLOAD := README.md \
	docs/*.pdf \
	$(LICENSE)

# Get just the top part (not dirname) of each entry so cp -r does the right thing
PAYLOAD_TOPS := $(foreach v,$(PAYLOAD),$(shell echo $v | cut -d'/' -f1))
# And the payload (including expanded projects) with the PKG_DIR prepended
PKG_PAYLOAD := $(addprefix $(PKG_DIR)/, $(PAYLOAD) $(basename $(SUB_PACKAGES)))

# OS detection & changes
UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
  MD5BIN=md5sum
endif
ifeq ($(UNAME), Darwin)
  MD5BIN=md5
endif
ifeq ($(UNAME), FreeBSD)
  MD5BIN=md5
endif

.PHONY: all clean $(CATEGORIES)

all: $(PACKAGE)

# Go into each category's subdir and break open the archives there
# into the corresponding subdir in the PKG_DIR
$(CATEGORIES):
	@mkdir -p $(PKG_DIR)/$@

	@for dir in $(wildcard $@/*); \
	do \
	        $(MAKE) -C $$dir clean; \
		$(MAKE) -C $$dir; \
	done 

	@for tb in $(wildcard $@/*/$(TARBALLS)); do \
	  tar -xzf $$tb -C $(PKG_DIR)/$@; \
	done

	@for zf in $(wildcard $@/*/$(ZIPFILES)); do \
	  unzip -qo $$zf -d $(PKG_DIR)/$@; \
	done



$(PACKAGE): $(CATEGORIES) $(PAYLOAD)
	@mkdir -p $(PKG_DIR)
	@cp -r $(PAYLOAD_TOPS) $(PKG_DIR)
	@zip -qXr  $(PACKAGE) $(PKG_PAYLOAD)
	@$(MD5BIN) $(PACKAGE)
	@rm -rf $(PKG_DIR) 

clean:
	@rm -rf $(PACKAGE) $(PKG_DIR)
