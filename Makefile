# Make file for LexLPeg external lexer for Scintilla.
# Copyright 2010-2013 Mitchell mitchell.att.foicica.com

.SUFFIXES: .cxx .c .o .h .a

ifeq (win, $(findstring win, $(MAKECMDGOALS)))
  CC = i686-w64-mingw32-gcc
  CPP = i686-w64-mingw32-g++
  plat_flag =
  LUAFLAGS = -D_WIN32 -DWIN32
  LDFLAGS = -g -static -mwindows -s LexLPeg.def -Wl,--enable-stdcall-fixup
  luadoc = luadoc_start.bat
else
  CC = gcc -fPIC
  CPP = g++ -fPIC
  plat_flag = -DGTK
  LUAFLAGS = -DLUA_USE_LINUX
  LDFLAGS = -g -Wl,-soname,liblexlpeg.so.0 -Wl,-fvisibility=hidden
  luadoc = luadoc
endif

# Lua
vpath %.c scite/lua/src scite/lua/src/lib
lua_objs = lapi.o lcode.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o lmem.o \
           lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o ltm.o \
           lundump.o lvm.o lzio.o \
           lauxlib.o lbaselib.o ldblib.o liolib.o lmathlib.o ltablib.o \
           lstrlib.o loadlib.o loslib.o linit.o \
           lpeg.o

# Scintilla
sci_flags = -g -pedantic $(plat_flag) -Iscintilla/include -Iscintilla/lexlib \
            -DSCI_LEXER -Wall -Wno-missing-braces -Wno-char-subscripts
vpath %.cxx scintilla/lexlib
lex_objs = PropSetSimple.o WordList.o LexerModule.o LexerSimple.o LexerBase.o \
           Accessor.o

# Build.

all: liblexlpeg.so
m64: liblexlpeg.x86_64.so
win32: LexLPeg.dll

liblexlpeg.so: LexLPeg.o $(lua_objs) $(lex_objs)
	$(CPP) -shared $(LDFLAGS) -o lexers/$@ $^
liblexlpeg.x86_64.so: lexers/liblexlpeg.so
	mv lexers/$< lexers/$@
LexLPeg.dll: LexLPeg.o $(lua_objs) $(lex_objs)
	$(CPP) -shared $(LDFLAGS) -o lexers/$@ $^
LexLPeg.o: LexLPeg.cxx
	$(CPP) $(sci_flags) $(LUAFLAGS) -DLPEG_LEXER_EXTERNAL -Iscite/lua/include -c $<
.c.o:
	$(CC) -Iscite/lua/include $(LUAFLAGS) -c $<
.cxx.o:
	$(CPP) $(sci_flags) -c $<
clean:
	rm -f *.o lexers/*.so lexers/*.dll

# Documentation.

doc: manual luadoc
manual: doc/*.md *.md
	doc/bombay -d doc -t doc --title Scintillua --navtitle Manual $^
luadoc: lexers/lexer.lua scintillua.luadoc
	$(luadoc) -d doc -t doc --doclet doc/markdowndoc $^
cleandoc:
	rm -f doc/manual/*.html
	rm -rf doc/api

# Package.

basedir = scintillua$(shell grep '^\#\#' CHANGELOG.md | head -1 | \
                            cut -d ' ' -f 2)

release: doc lexers/LexLPeg.dll lexers/liblexlpeg.so lexers/liblexlpeg.x86_64.so
	./gen_lexer_props.lua
	hg archive $(basedir)
	rm $(basedir)/.hg*
	cp -r lexers/*.so lexers/*.dll $(basedir)/lexers/
	cp lpeg.c $(basedir)
	cp -rL doc/ $(basedir)
	zip -r releases/$(basedir).zip $(basedir)
	rm -r $(basedir)
