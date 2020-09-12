# Copyright 2010-2020 Mitchell mitchell.att.foicica.com. See LICENSE.
# Make file for LexLPeg external lexer for Scintilla.

ifeq (win, $(MAKECMDGOALS))
  CC = x86_64-w64-mingw32-gcc
  CXX = x86_64-w64-mingw32-g++
  plat_flag =
  LUA_CFLAGS = -D_WIN32 -DWIN32
  LDFLAGS = -g -static -mwindows -s LexLPeg.def -Wl,--enable-stdcall-fixup
  lexer = lexers/LexLPeg.dll
  luadoc = luadoc_start.bat
else
  CC = gcc -fPIC
  CXX = g++ -fPIC
  plat_flag = -DGTK
  LUA_CFLAGS = -DLUA_USE_LINUX
  LDFLAGS = -g -Wl,-soname,liblexlpeg.so.0 -Wl,-fvisibility=hidden
  lexer = lexers/liblexlpeg.so
  luadoc = luadoc
endif

# Scintilla.
sci_flags = --std=c++17 -g -pedantic $(plat_flag) -Iscintilla/include \
            -Iscintilla/lexlib -DSCI_LEXER -W -Wall -Wno-unused
lex_objs = PropSetSimple.o WordList.o LexerModule.o LexerSimple.o LexerBase.o \
           Accessor.o DefaultLexer.o

# Lua.
lua_objs = lapi.o lcode.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o lmem.o \
           lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o ltm.o \
           lundump.o lvm.o lzio.o \
           lauxlib.o lbaselib.o ldblib.o liolib.o lmathlib.o ltablib.o \
           lstrlib.o loadlib.o loslib.o linit.o
lua_lib_objs = lpcap.o lpcode.o lpprint.o lptree.o lpvm.o

# Build.

all: $(lexer)
win: $(lexer)
deps: scintilla lua lua/src/lib/lpeg

$(lex_objs): %.o: scintilla/lexlib/%.cxx
	$(CXX) $(sci_flags) -c $<
$(lua_objs): %.o: lua/src/%.c
	$(CC) -Os -std=c99 -Ilua/src $(LUA_CFLAGS) -c $<
$(lua_lib_objs): %.o: lua/src/lib/%.c
	$(CC) -std=c99 -Os -Ilua/src $(LUA_CFLAGS) -c $<
LexLPeg.o: LexLPeg.cxx
	$(CXX) $(sci_flags) $(LUA_CFLAGS) -Ilua/src -c $<
$(lexer): $(lex_objs) $(lua_objs) $(lua_lib_objs) LexLPeg.o
	$(CXX) -shared $(LDFLAGS) -o $@ $^
clean: ; rm -f *.o

# Documentation.

docs: docs/index.md docs/api.md $(wildcard docs/*.md) | \
      docs/_layouts/default.html
	for file in $(basename $^); do \
		cat $| | docs/fill_layout.lua $$file.md > $$file.html; \
	done
docs/index.md: README.md ; cp $< $@
docs/api.md: lexers/lexer.lua scintillua.luadoc
	$(luadoc) --doclet docs/markdowndoc $^ > $@
cleandocs: ; rm -f docs/*.html docs/index.md docs/api.md

# Releases.

ifndef NIGHTLY
  basedir = scintillua_$(shell grep '^\#\#\#' docs/changelog.md | head -1 | \
                               cut -d ' ' -f 2)
else
  basedir = scintillua_nightly_$(shell date +"%F")
endif

ifneq (, $(shell hg summary 2>/dev/null))
  archive = hg archive -X ".hg*" $(1)
else
  archive = git archive HEAD --prefix $(1)/ | tar -xf -
endif

$(basedir): ; $(call archive,$@)
release: $(basedir)
	make clean deps docs sign-deps
	make -j4
	make clean && make -j4 CC=i686-w64-mingw32-gcc CXX=i686-w64-mingw32-g++ \
		win && mv lexers/LexLPeg.dll lexers/LexLPeg32.dll
	make clean && make -j4 win
	cp -r docs *.asc $<
	cp lexers/*.so lexers/*.dll $</lexers/
	zip -r $<.zip $< && rm -r $< && gpg -ab $<.zip

# External dependencies.

scintilla_tgz = scintilla445.tgz
lua_tgz = lua-5.1.4.tar.gz
lpeg_tgz = lpeg-1.0.0.tar.gz

$(scintilla_tgz): ; wget https://www.scintilla.org/$@
scintilla: | $(scintilla_tgz) ; tar xzf $|
$(lua_tgz): ; wget http://www.lua.org/ftp/$@
$(lpeg_tgz): ; wget http://www.inf.puc-rio.br/~roberto/lpeg/$@
lua: | $(lua_tgz) ; mkdir $@ && tar xzf $| -C $@ && mv $@/*/* $@
lua/src/lib/lpeg: | $(lpeg_tgz)
	mkdir -p $@ && tar xzf $| -C $@ && mv $@/*/*.c $@/*/*.h $(dir $@)
sign-deps: | $(scintilla_tgz) $(lua_tgz) $(lpeg_tgz)
	@for file in $|; do gpg -ab $$file; done
verify-deps: | $(wildcard $(basename $(wildcard *.asc)))
	@for file in $|; do echo "$$file"; gpg --verify $$file.asc || return 1; done
