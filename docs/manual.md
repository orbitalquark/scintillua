## Scintillua Manual

Scintillua can be used in the following ways:

* Dropped into an existing installation of a Scintilla-based application as an external lexer.
* Compiled directly into your Scintilla-based application.
* Used as a standalone Lua library (Scintilla is not required).

These usages are discussed in the following sections.

### Drop-in External Lexer

Scintillua can be dropped into any existing installation of a Scintilla-based application as
long as that application supports [Lexilla][] 5.1.0 or greater.

Scintillua releases come with two external lexers in the *lexers/* directory: *libscintillua.so*,
which is a 64-bit Linux shared library; and *Scintillua.cxx*, which is a 64-bit Windows DLL.

[Lexilla]: https://scintilla.org/LexillaDoc.html

#### Using Scintillua with SciTE

[SciTE][] is the SCIntilla based Text Editor. Scintillua can be dropped into any SciTE
installation version 5.3.0 or higher with or without administrator privileges.

In order to install Scintillua for all users (likely requiring administrator privileges):

1. Unpack Scintillua to the root of your SciTE installation, typically *C:\Program Files\SciTE\\*
   on Windows and */usr/share/scite/* on Linux, and rename the directory to simply *scintillua*.
2. Add the following to the end of your *SciTEGlobal.properties*:

       import scintillua/scintillua

In order to install Scintillua for one user (e.g. yourself) without administrator privileges:

1. Unpack Scintillua to a location of your choosing.
2. Add the following to the end of your *SciTEUser.properties* on Windows or
   *.SciTEUser.properties* on Linux:

       import /path/to/scintillua/scintillua
       lexilla.context.scintillua.lexers=/path/to/scintillua/lexers

   where `/path/to/scintillua/lexers` is the full path of Scintillua's *lexers/* directory from
   step 1.

With Scintillua installed, SciTE will use Scintillua's Lua lexers whenever possible (as indicated
in *scintillua.properties*). If a Lua lexer is loaded but you prefer to use a different
one, add to your *SciTEUser.properties* (Windows) or *.SciTEUser.properties* (Linux) file a
`lexer.$(file.patterns.`*`name`*`)=scintillua.`*`name`* line, where *`name`* is the name of
the lexer you prefer. Note that Scintillua lexers have a "scintillua." prefix when used with SciTE.

Scintillua comes with a set of universal color themes in its *themes/* directory. By default, the
'scite' theme is used, which is similar to SciTE's default color theme. You can use a different
theme by importing it in a properties file. For example:

    import /path/to/scintillua/themes/light

Scintillua's lexers support the following properties which can also be set from a properties file:

* `fold.scintillua.by.indentation`: Whether or not to fold based on indentation level if a lexer does not
   have a folder. Some lexers automatically enable this option. It is disabled by default.
* `fold.scintillua.line.groups`: Whether or not to fold multiple, consecutive line groups (such as line
   comments and import statements) and only show the top line. This option is disabled by default.
* `fold.scintillua.on.zero.sum.lines`: Whether or not to mark as a fold point lines that contain both an
   ending and starting fold point. For example, `} else {` would be marked as a fold point. This
   option is disabled by default.
* `fold.scintillua.compact`: Whether or not to include in a fold any subsequent blank lines. It
   is disabled by default.

If you get incorrect or no syntax highlighting, check the following:

1. Does the language in question have a Lua lexer in Scintillua's *lexers/* directory? If not,
   you will have to [write one][].
2. Does Scintillua's *scintillua.properties* have your language's file extension defined? If not,
   add it to the `file.patterns.`*`name`* property.
3. Does the file extension recognized in Scintillua's *scintillua.properties* correspond to the
   language in question? If not, add or re-assign it to the appropriate Lua lexer. Do not forget
   the "scintillua." prefix for lexers.

Feel free to [contribute][] new lexers, as well as submit corrections, updates, or additions
to file types.

**Note:** any Scintilla lexer-specific features in SciTE will not work in Scintillua's lexers.
These include, but are not limited to:

* Style, keyword, and folding properties in *\*.properties* files.
* Python colon matching.
* HTML/XML tag auto-completion.

[SciTE]: https://scintilla.org/SciTE.html
[write one]: api.html#lexer
[contribute]: index.html#contribute

#### Using Scintillua with Other Apps

In order to drop Scintillua into any other existing installation of a Scintilla-based application
that supports the Lexilla protocol, that application must allow you to:

* Specify the location of, and/or load Scintillua's *Scintillua.dll* (Windows) or
   *libscintillua.so* (Linux) library.
* Specify the path to Scintillua's *lexers/* directory via an internal call to the Lexilla
   protocol's `SetLibraryProperty()` function using the "scintillua.lexers" key.
* Load a lexer using the Lexilla protocol's `CreateLexer()` function, passing in the name of
   a Lua lexer to load (without the *.lua* extension).
* Give the resulting `ILexer5*` pointer to Scintilla, e.g. via Scintilla's [SCI_SETILEXER][]
   message.

The Scintillua lexer largely behaves like a normal Scintilla lexer. However, unlike most
other lexers Scintillua does not have static style numbers, which makes styling a bit more
complicated. Your application must call the lexer's `NamedStyles()` function (which is defined
by the `ILexer5` interface), which returns the number of currently defined styles. It must then
iterate over those style numbers, calling `NameOfStyle()`, in order to obtain a map of style
names to numbers. With that information, your application can then specify style settings for
style numbers. Here's an example of how [SciTE][] does it:

    // Scintillua's style numbers are not constant, so ask it for names of styles
    // and create a mapping of style numbers to more constant style definitions.
    // For example, if Scintillua reports for the cpp lexer that style number 2 is
    // associated with comments, create the property:
    //   style.scintillua.cpp.2=$(scintillua.styles.comment)
    // That way the user can define 'scintillua.styles.comment' once and it will
    // be used for whatever the style number for comments is in any given lexer.
    const auto setStyle = [this, &key, &languageName](int style) {
      char styleName[64] = "";
      char propStr[128] = "";
      sprintf(key, "style.%s.%0d", languageName, style);
      wEditor.NameOfStyle(style, styleName);
      sprintf(propStr, "$(scintillua.styles.%s)", styleName);
      props.Set(key, propStr);
    };
    const int namedStyles = wEditor.NamedStyles(); // includes predefined styles
    const int LastPredefined = static_cast<int>(Scintilla::StylesCommon::LastPredefined);
    const int numPredefined = LastPredefined - StyleDefault + 1;
    for (int i = 0; i < std::min(namedStyles - numPredefined, StyleDefault); i++) {
      setStyle(i);
    }
    for (int i = StyleDefault; i <= LastPredefined; i++) {
      setStyle(i);
    }
    for (int i = LastPredefined + 1; i < namedStyles; i++) {
      setStyle(i);
    }

Scintillua's lexers support the following properties:

* `fold`: Whether or not folding is enabled for the lexers that support it. This option is
   disabled by default. Set to `1` to enable.
* `fold.scintillua.by.indentation`: Whether or not to fold based on indentation level if a
   lexer does not have a folder. Some lexers automatically enable this option. It is disabled
   by default. Set to `1` to enable.
* `fold.scintillua.line.groups`: Whether or not to fold multiple, consecutive line groups (such
   as line comments and import statements) and only show the top line. This option is disabled
   by default. Set to `1` to enable.
* `fold.scintillua.on.zero.sum.lines`: Whether or not to mark as a fold point lines that contain
   both an ending and starting fold point. For example, `} else {` would be marked as a fold
   point. This option is disabled by default. Set to `1` to enable.
* `fold.scintillua.compact`: Whether or not blank lines after an ending fold point are included
   in that fold. This option is disabled by default. Set to `1` to enable.

[SCI_SETILEXER]: https://scintilla.org/ScintillaDoc.html#SCI_SETILEXER
[SciTE]: https://scintilla.org/SciTE.html

### Compiling Scintillua Directly into an App

You can compile Scintillua directly (statically) into your Scintilla-based application by:

1. Adding *Scintillua.h* and *Scintillua.cxx* to your project's sources.
2. Downloading and adding [Lua][] and [LPeg][] to your project's sources. Scintillua supports
   Lua 5.3+.
3. Adding infrastructure to build Lua, LPeg, *Scintillua.cxx*, and link them all into your
   application.

Here is a sample portion of a *Makefile* with Lua 5.3 as an example:

    # ...

    sci_flags = [flags used to compile Scintilla and Lexilla]
    scintillua_obj = Scintillua.o
    lua_flags = -Iscintillua/lua/src
    lua_objs = lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o linit.o llex.o lmem.o \
      lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o ltm.o lundump.o lvm.o lzio.o \
      lauxlib.o lbaselib.o lbitlib.o lcorolib.o ldblib.o liolib.o lmathlib.o loadlib.o loslib.o \
      lstrlib.o ltablib.o lutf8lib.o \
      lpcap.o lpcode.o lpprint.o lptree.o lpvm.o
    $(scintillua_obj): scintillua/Scintillua.cxx
    	g++ $(sci_flags) $(lua_flags) -c $< -o $@
    $(lua_objs): scintillua/lua/src/*.c scintillua/lua/src/lib/*.c
    	gcc $(lua_flags) -c $^

    # ...

    [your app]: [your dependencies] $(scintillua_obj) $(lua_objs)

**Windows note:** when cross-compiling for Windows statically, you will need to pass `-DNO_DLL`
when compiling *Scintillua.cxx*.

In order to use Scintillua's lexers in your application:

1. Call Scintillua's `SetLibraryProperty()` with "scintillua.lexers" as the key and the path to
   Scintillua's *lexers/* directory as the value.
2. Call Scintillua's `CreateLexer()` with the name of a Lua lexer (without the *.lua* extension)
   to load.
3. Call Scintilla's [SCI_SETILEXER][] message, passing the lexer returned in step 2.

For example, using the GTK platform:

    SetLibraryProperty("scintillua.lexers", "/path/to/lexers/");
    ILEXER5* lua_lexer = CreateLexer("lua");
    GtkWidget *sci = scintilla_new();
    send_scintilla_message(SCINTILLA(sci), SCI_SETILEXER, 0, (sptr_t)lua_lexer);

Your application will then have to query Scintillua for how many styles are currently defined
and what the names of those styles are in order to create a map of style names to style numbers
for specifying style settings. The previous [section](#using-scintillua-with-other-apps) has
an example of this process.

[Lua]: https://lua.org
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[Scintilla's SCI_SETILEXER]: https://scintilla.org/ScintillaDoc.html#SCI_SETILEXER
[SCI_SETILEXER]: api.html#SCI_SETILEXER

### Using Scintillua as a Lua Library

In order to use Scintillua as a Lua library, simply place the *lexers/* directory in your Lua
path (or modify Lua's `package.path` accordingly), `require()` the `lexer` library, [`load()`][]
a lexer, and call that lexer's [`lex()`][] function. Here is an example interactive Lua session
doing this:

    $> lua
    Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio
    > lexer_path = '/home/mitchell/code/scintillua/lexers/?.lua'
    > package.path = package.path .. ';' .. lexer_path
    > c = require('lexer').load('ansi_c')
    > tokens = c:lex('int void main() { return 0; }')
    > for i = 1, #tokens, 2 do print(tokens[i], tokens[i+1]) end
    type	4
    whitespace.ansi_c	5
    type	9
    whitespace.ansi_c	10
    identifier	14
    operator	15
    operator	16
    whitespace.ansi_c	17
    operator	18
    whitespace.ansi_c	19
    keyword	25
    whitespace.ansi_c	26
    number	27
    operator	28
    whitespace.ansi_c	29
    operator	30

[`load()`]: api.html#lexer.load
[`lex()`]: api.html#lexer.lex
