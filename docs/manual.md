## Scintillua Manual

Scintillua can be used in the following ways:

* Dropped into an existing installation of a Scintilla-based application as an
  external lexer.
* Compiled directly into your Scintilla-based application.
* Used as a standalone Lua library (Scintilla is not required).

These usages are discussed in the following sections.

### Drop-in External Lexer

Scintillua can be dropped into any existing installation of a Scintilla-based
application as long as that application supports the [Lexilla][] interface as
defined in Scintilla 4.4.5.

Scintillua releases come with three external lexers in the *lexers/* directory:
*liblexlpeg.so*, which is a 64-bit Linux shared library; *LexLPeg.cxx*, which is
a 64-bit Windows DLL, and *LexLPeg32.dll*, which is a 32-bit Windows DLL.

[Lexilla]: https://scintilla.org/ScintillaDoc.html#Lexilla

#### Using Scintillua with SciTE

[SciTE][] is the SCIntilla based Text Editor. Scintillua can be dropped into any
SciTE installation version 4.4.5 or higher with or without administrator
privileges.

In order to install Scintillua for all users (likely requiring administrator
privileges):

1. Unpack Scintillua to a temporary directory and move the *lexers/* directory
   to the root of your SciTE installation, typically *C:\Program Files\SciTE\\*
   on Windows and */usr/share/scite/* on Linux.
2. Add the following to the end of your *SciTEGlobal.properties*:

       import lexers/lpeg

In order to install Scintillua for one user (e.g. yourself) without
administrator privileges:

1. Unpack Scintillua to a temporary directory and move the *lexers/* directory
   to a location of your choosing.
2. Add the following to the end of your *SciTEUser.properties* on Windows or
   *.SciTEUser.properties* on Linux:

       import /path/to/lexers/lpeg
       lexilla.context.lpeg.home=/path/to/lexers

   where `/path/to/lexers` is the full path of *lexers/* from step 1.

**Win32 note:** if you are on a 32-bit Windows system, you will need to replace
*lexers/LexLPeg.dll* with *lexers/LexLPeg32.dll*.

With Scintillua installed, SciTE will use Scintillua's Lua lexers whenever
possible (as indicated in *lexers/lpeg.properties*). If a Lua lexer is loaded
but you prefer to use a different one, add to your *SciTEUser.properties*
(Windows) or *.SciTEUser.properties* (Linux) file a
`lexer.$(file.patterns.`*`name`*`)=`*`name`* line, where *`name`* is the name of
the lexer you prefer. Note that Scintillua lexers have a "lpeg_" prefix when
used with SciTE.

Scintillua's lexers support the following properties:

* `lexilla.context.lpeg.color.theme`: The color theme in *lexers/themes/* to
  use. Currently supported themes are `light`, `dark`, and `scite`.
* `fold.by.indentation`: Whether or not to fold based on indentation level if a
  lexer does not have a folder. Some lexers automatically enable this option. It
  is disabled by default.
* `fold.line.groups`: Whether or not to fold multiple, consecutive line groups
  (such as line comments and import statements) and only show the top line. This
  option is disabled by default.
* `fold.on.zero.sum.lines`: Whether or not to mark as a fold point lines that
  contain both an ending and starting fold point. For example, `} else {` would
  be marked as a fold point. This option is disabled by default.

If you get incorrect or no syntax highlighting, check the following:

1. Does the language in question have a Lua lexer in Scintillua's *lexers/*
   directory? If not, you will have to [write one][].
2. Does Scintillua's *lexers/lpeg.properties* have your language's file
   extension defined? If not, add it to the `file.patterns.`*`name`* property.
3. Does the file extension recognized in Scintillua's *lexers/lpeg.properties*
   correspond to the language in question? If not, add or re-assign it to the
   appropriate Lua lexer.

Feel free to [contribute][] new lexers, as well as submit corrections, updates,
or additions to file types.

**Note:** any Scintilla lexer-specific features in SciTE will not work in
Scintillua's lexers. These include, but are not limited to:

* Style, keyword, and folding properties in *\*.properties* files.
* Python colon matching.
* HTML/XML tag auto-completion.

[SciTE]: https://scintilla.org/SciTE.html
[write one]: api.html#lexer
[contribute]: README.html#Contribute

#### Using Scintillua with Other Apps

In order to drop Scintillua into any other existing installation of a
Scintilla-based application that supports the Lexilla interface, that
application must allow you to:

* Define the location of Scintillua's *LexLPeg.dll* (Windows) or *liblexlpeg.so*
  (Linux) library.
* Specify the path to Scintillua's *lexers/* via an internal call to the Lexilla
  interface's `SetLibraryProperty()` function using the "lpeg.home" key.

Scintillua's lexers support the following properties:

* `lexer.lpeg.color.theme`: The color theme in *lexers/themes/* to use.
  Currently supported themes are `light`, `dark`, and `scite`. Note that
  Scintillua cannot set styles by itself. Your application must allow Scintillua
  to do so via Scintillua's [SCI_GETDIRECTFUNCTION][] and [SCI_SETDOCPOINTER][]
  [API][] calls. Otherwise, your application can [read][] from SciTE-style style
  definitions generated by Scintillua and manually set styles.
* `fold`: Whether or not folding is enabled for the lexers that support it. This
  option is disabled by default. Set to `1` to enable.
* `fold.by.indentation`: Whether or not to fold based on indentation level if a
  lexer does not have a folder. Some lexers automatically enable this option. It
  is disabled by default. Set to `1` to enable.
* `fold.line.groups`: Whether or not to fold multiple, consecutive line groups
  (such as line comments and import statements) and only show the top line. This
  option is disabled by default. Set to `1` to enable.
* `fold.on.zero.sum.lines`: Whether or not to mark as a fold point lines that
  contain both an ending and starting fold point. For example, `} else {` would
  be marked as a fold point. This option is disabled by default. Set to `1` to
  enable.
* `fold.compact`: Whether or not blank lines after an ending fold point are
  included in that fold. This option is disabled by default. Set to `1` to
  enable.

[SCI_GETDIRECTFUNCTION]: api.html#SCI_GETDIRECTFUNCTION
[SCI_SETDOCPOINTER]: api.html#SCI_SETDOCPOINTER
[API]: api.html
[read]: api.html#styleNum

### Compiling Scintillua Directly into an App

You can compile Scintillua directly (statically) into your Scintilla-based
application by:

1. Adding *LexLPeg.h* and *LexLPeg.cxx* to your project's sources.
2. Downloading and adding [Lua][] and [LPeg][] to your project's sources.
   Scintillua supports Lua 5.1, 5.2, and 5.3.
3. Adding infrastructure to build Lua, LPeg, *LexLPeg.cxx*, and link them all
   into your application.

Here is a sample portion of a *Makefile* with Lua 5.3 as an example:

    # ...

    SCI_FLAGS = [flags used to compile Scintilla]
    SCINTILLUA_LEXER = LexLPeg.o
    SCINTILLUA_SRC = scintillua/LexLPeg.cxx
    LUA_FLAGS = -Iscintillua/lua/src
    LUA_OBJS = lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o \
               linit.o llex.o lmem.o lobject.o lopcodes.o lparser.o lstate.o \
               lstring.o ltable.o ltm.o lundump.o lvm.o lzio.o \
               lauxlib.o lbaselib.o lbitlib.o lcorolib.o ldblib.o liolib.o \
               lmathlib.o loadlib.o loslib.o lstrlib.o ltablib.o lutf8lib.o \
               lpcap.o lpcode.o lpprint.o lptree.o lpvm.o
    LUA_SRCS = scintillua/lua/src/*.c scintillua/lua/src/lib/*.c
    $(SCINTILLUA_LEXER): $(SCINTILLUA_SRC)
    	g++ $(SCI_FLAGS) $(LUA_FLAGS) -DNO_SCITE -c $< -o $@
    $(LUA_OBJS): $(LUA_SRCS)
    	gcc $(LUA_FLAGS) $(INCLUDEDIRS) -c $^

    # ...

    [your app]: [your dependencies] $(SCINTILLUA_LEXER) $(LUA_OBJS)

**Win32 note:** when cross-compiling for Windows statically, you will need to
pass `-DNO_DLL` when compiling *LexLPeg.cxx*.

In order to use Scintillua's lexers in your application:

1. Call Scintillua's `SetLibraryProperty()` with "lpeg.home" as the key and the
   path to Scintillua's *lexers/* directory as the value.
2. Optionally call `SetLibraryProperty()` with "lpeg.color.theme" as the key and
   one of the theme names in Scintillua's *lexers/themes/* directory as the
   value. You can omit this call if you want to manage Scintilla styles
   yourself.
3. Call Scintillua's `CreateLexer()` with either `NULL` or the name of a Lua
   lexer to use in your application.
4. Call Scintilla's [SCI_SETILEXER][], passing the lexer returned in step 3.
5. If you called `CreateLexer()` with `NULL`, then call Scintillua's
   [SCI_SETLEXERLANGUAGE][] [API][] to use the given Lua lexer in your
   application.

For example, using the GTK platform:

    SetLibraryProperty("lpeg.home", "/path/to/lexers/");
    SetLibraryProperty("lpeg.color.theme", "light");
    ILEXER5* lua_lexer = CreateLexer("lua");
    GtkWidget *sci = scintilla_new();
    send_scintilla_message(SCINTILLA(sci), SCI_SETILEXER, 0, (sptr_t)lua_lexer);

For more information on how to communicate with Scintillua, including how to
work with styles, please see the [API][] Documentation.

[Lua]: https://lua.org
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[SCI_SETILEXER]: https://scintilla.org/ScintillaDoc.html#SCI_SETILEXER
[SCI_SETLEXERLANGUAGE]: api.html#SCI_SETLEXERLANGUAGE
[API Documentation]: api.html

### Using Scintillua as a Lua Library

In order to use Scintillua as a Lua library, simply place the *lexers/*
directory in your Lua path (or modify Lua's `package.path` accordingly),
`require()` the `lexer` library, [`load()`][] a lexer, and call that lexer's
[`lex()`][] function. Here is an example interactive Lua session doing this:

    $> lua
    Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio
    > lexer_path = '/home/mitchell/code/scintillua/lexers/?.lua'
    > package.path = package.path .. ';' .. lexer_path
    > c = require('lexer').load('ansi_c')
    > tokens = c:lex('int void main() { return 0; }')
    > for i = 1, #tokens, 2 do print(tokens[i], tokens[i+1]) end
    type	4
    ansi_c_whitespace	5
    type	9
    ansi_c_whitespace	10
    identifier	14
    operator	15
    operator	16
    ansi_c_whitespace	17
    operator	18
    ansi_c_whitespace	19
    keyword	25
    ansi_c_whitespace	26
    number	27
    operator	28
    ansi_c_whitespace	29
    operator	30

[`load()`]: api.html#lexer.load
[`lex()`]: api.html#lexer.lex
