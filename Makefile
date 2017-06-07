# A simple makefile for creating the High Resolution CFD Models bundled product
VERSION    := `git describe --tags`
PRODUCT    := Process Models Bundle
PROD_SNAME := ProcessModels_bundle
LICENSE    := CCSI_TE_LICENSE_$(PROD_SNAME).txt
PKG_DIR    := CCSI_$(PROD_SNAME)_$(VERSION)
PACKAGE    := $(PKG_DIR).zip

CATEGORIES := SolidSorbents Solvents OtherModels

# Where Jenkins should checkout ^/projects/common/trunk/
COMMON     := .ccsi_common
LEGAL_DOCS := LEGAL \
           CCSI_TE_LICENSE.txt

TARBALLS := *.tgz
ZIPFILES := *.zip

# The bundled packages, as found in each category subdir
SUB_PACKAGES := $(foreach c,$(CATEGORIES), $(wildcard $c/$(TARBALLS) $c/$(ZIPFILES)))

PAYLOAD := docs/*.pdf \
	LEGAL \
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

	@for tb in $(wildcard $@/$(TARBALLS)); do \
	  tar -xzf $$tb -C $(PKG_DIR)/$@; \
	done

	@for zf in $(wildcard $@/$(ZIPFILES)); do \
	  unzip -qo $$zf -d $(PKG_DIR)/$@; \
	done

$(PACKAGE): $(PAYLOAD) $(CATEGORIES)
	@mkdir -p $(PKG_DIR)
	@cp -r $(PAYLOAD_TOPS) $(PKG_DIR)
	@zip -qXr  $(PACKAGE) $(PKG_PAYLOAD)
	@$(MD5BIN) $(PACKAGE)
	@rm -rf $(PKG_DIR) $(LEGAL_DOCS) $(LICENSE)

$(LICENSE): CCSI_TE_LICENSE.txt 
	@sed "s/\[SOFTWARE NAME \& VERSION\]/$(PRODUCT) v.$(VERSION)/" < CCSI_TE_LICENSE.txt > $(LICENSE)

$(LEGAL_DOCS):
	@if [ -d $(COMMON) ]; then \
	  cp $(COMMON)/$@ .; \
	else \
	  svn -q export ^/projects/common/trunk/$@; \
	fi

clean:
	@rm -rf $(PACKAGE) $(PKG_DIR) $(LEGAL_DOCS) $(LICENSE)
