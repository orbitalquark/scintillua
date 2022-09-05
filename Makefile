# Copyright 2010-2022 Mitchell. See LICENSE.

CFLAGS := -Os
CXXFLAGS := -Os -std=c++17
WGET = wget -O $@

# Utility functions.

objs = $(addsuffix .o, $(filter-out $(2), $(basename $(notdir $(wildcard $(1))))))
win-objs = $(addprefix win-, $(1))
all-objs = $(1) $(call win-objs, $(1))

define build-cxx =
  $(CXX) $(CXXFLAGS) -c $< -o $@
endef
define build-cc =
  $(CC) $(CFLAGS) -c $< -o $@
endef
define build-so =
  $(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS) $(LDLIBS)
endef

# Scintillua.
scintillua_objs := $(call objs, Scintillua.cxx)

$(call all-objs, $(scintillua_objs)): CXXFLAGS += $(sci_flags) $(lua_flags)

# Lexilla.
lexlib_objs := $(call objs, $(addprefix lexilla/lexlib/, $(addsuffix .cxx, PropSetSimple Accessor DefaultLexer)))

sci_flags = -pedantic -Iscintilla/include -Ilexilla/include -Ilexilla/lexlib -DSCI_LEXER -W -Wall \
  -Wno-unused

$(call all-objs, $(lexlib_objs)): CXXFLAGS += $(sci_flags)

$(lexlib_objs): %.o: lexilla/lexlib/%.cxx ; $(build-cxx)
$(call win-objs, $(lexlib_objs)): win-%.o: lexilla/lexlib/%.cxx ; $(build-cxx)
$(call all-objs, $(scintillua_objs)): Scintillua.cxx ; $(build-cxx)

# Lua.
lua_objs := $(call objs, lua/src/*.c, lua luac lbitlib lcorolib ldblib liolib loadlib loslib linit)
lua_lib_objs := $(call objs, lua/src/lib/*.c)

lua_flags := -Ilua/src

$(call all-objs, $(lua_objs)): CFLAGS += $(lua_flags) -ULUA_LIB
$(call all-objs, $(lua_lib_objs)): CFLAGS += $(lua_flags)

$(lua_objs): %.o: lua/src/%.c ; $(build-cc)
$(call win-objs, $(lua_objs)): win-%.o: lua/src/%.c ; $(build-cc)
$(lua_lib_objs): %.o: lua/src/lib/%.c ; $(build-cc)
$(call win-objs, $(lua_lib_objs)): win-%.o: lua/src/lib/%.c ; $(build-cc)

ifdef DEBUG
  #CFLAGS += -g -O0
  CXXFLAGS += -g -O0
  lua_flags += -DLUA_USE_APICHECK
  sci_flags += -UNDEBUG -DDEBUG
endif

# Compilers and platform-specific flags for all objects.

linux_objs := $(scintillua_objs) $(lexlib_objs) $(lua_objs) $(lua_lib_objs)
win_objs := $(call win-objs, $(linux_objs))

# Compile natively for Linux.
$(linux_objs): CC := gcc
$(linux_objs): CXX := g++
$(linux_objs): CFLAGS += -fPIC
$(linux_objs): CXXFLAGS += -fPIC
$(linux_objs): lua_flags += -DLUA_USE_LINUX

# Cross-compile for Windows.
$(win_objs): CC := x86_64-w64-mingw32-gcc-posix
$(win_objs): CXX := x86_64-w64-mingw32-g++-posix
$(win_objs): CFLAGS += -mms-bitfields
$(win_objs): CXXFLAGS += -mms-bitfields
$(win_objs): lua_flags += -DLUA_BUILD_AS_DLL -DLUA_LIB

# Shared libraries.

linux_so := lexers/libscintillua.so
win_so := lexers/Scintillua.dll

.PHONY: all win
.DEFAULT_GOAL := all
all: $(linux_so)
win: $(win_so)

# Compile natively for Linux.

$(linux_so): $(linux_objs)

$(linux_so): CXX := g++
$(linux_so): LDFLAGS := -shared -g -Wl,-soname,libscintillua.so -Wl,-fvisibility=hidden

$(linux_so): ; $(build-so)

# Cross-compile for Windows.

$(win_so): $(win_objs)

$(win_so): CXX := x86_64-w64-mingw32-g++-posix
$(win_so): LDFLAGS := -shared -g -static -mwindows -s Scintillua.def -Wl,--enable-stdcall-fixup

$(win_so): ; $(build-so)

# Clean.

.PHONY: clean clean-win clean-all
clean: ; rm -f $(linux_objs) $(linux_so)
clean-win: ; rm -f $(win_objs) $(win_so)
clean-all: clean clean-win

# Documentation.

.PHONY: docs
docs: docs/index.md docs/api.md $(wildcard docs/*.md) | docs/_layouts/default.html
	for file in $(basename $^); do cat $| | docs/fill_layout.lua $$file.md > $$file.html; done
docs/index.md: README.md
	sed -e 's/^\# [[:alpha:]]\+/## Introduction/;' -e \
		's|https://[[:alpha:]]\+\.github\.io/[[:alpha:]]\+/||;' $< > $@
docs/api.md: lexers/lexer.lua ; luadoc --doclet docs/markdowndoc $^ > $@

# Releases.

basedir = scintillua_$(shell grep '^\#\#\#' docs/changelog.md | head -1 | cut -d ' ' -f 2)

.PHONY: release
release: $(basedir).zip | deps docs

ifneq (, $(shell hg summary 2>/dev/null))
  archive = hg archive -X ".hg*" $(1)
else
  archive = git archive HEAD --prefix $(1)/ | tar -xf -
endif

$(basedir): $(linux_so) $(win_so)
	$(call archive,$@)
	cp -r docs $@
	cp $^ $@/lexers/
$(basedir).zip: $(basedir) ; zip -r $<.zip $< && rm -r $<

# Tests.

.PHONY: tests test-lexers test-scite test-wscite
tests: test-lexers test-scite test-wscite
test-lexers: tests.lua ; lua $<
# Tests SciTE GTK using ~/.SciTEUser.properties.
test-scite: scintilla
	make -C scintilla/gtk -j16
	make -C lexilla/src -j16
	make -C scite/gtk -j16
	scite/bin/SciTE
# Tests, via Wine, SciTE Win64 using SciTEGlobal.properties.
wscite_zip = wscite530.zip
/tmp/$(wscite_zip): ; wget -O $@ https://www.scintilla.org/$(wscite_zip)
/tmp/wscite: /tmp/$(wscite_zip)
	unzip -d /tmp $<
	ln -s `pwd`/lexers /tmp/wscite
	sed -i 's/technology=1/technology=0/;' /tmp/wscite/SciTEGlobal.properties
	echo "import scintillua/scintillua" >> /tmp/wscite/SciTEGlobal.properties
test-wscite: /tmp/wscite
	cd /tmp/wscite && WINEPREFIX=/tmp/wscite/.wine WINEARCH=win64 wine SciTE

# External dependencies.

.PHONY: deps
deps: scintilla lexilla lua lua/src/lib/lpeg

scintilla_tgz = scintilla501.tgz
lexilla_tgz = lexilla510.tgz
lua_tgz = lua-5.3.5.tar.gz
lpeg_tgz = lpeg-1.0.2.tar.gz

$(scintilla_tgz): ; $(WGET) https://www.scintilla.org/$@
scintilla: | $(scintilla_tgz)
	if [ -d $@/.hg ]; then \
		hg --cwd $@ update -C -r `hg --cwd $@ summary | head -1 | cut -d: -f2`; \
	else \
		if [ -d $@ ]; then rm -r $@; fi; \
		tar xzf $|; \
	fi
$(lexilla_tgz): ; $(WGET) https://www.scintilla.org/$@
lexilla: | $(lexilla_tgz) ; tar xzf $|
$(lua_tgz): ; $(WGET) http://www.lua.org/ftp/$@
$(lpeg_tgz): ; $(WGET) http://www.inf.puc-rio.br/~roberto/lpeg/$@
lua: | $(lua_tgz) ; mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
lua/src/lib/lpeg: | $(lpeg_tgz) ; mkdir -p $@ && tar xzf $| -C $@ && mv $@/*/*.c $@/*/*.h $(dir $@)
