# Scintillua

Scintillua adds dynamic [Lua][] [LPeg][] lexers to [Scintilla][]. It is the
quickest way to add new or customized syntax highlighting and code folding for
programming languages to any Scintilla-based text editor or IDE. Scintillua was
designed to be dropped into or compiled with any Scintilla environment.

Scintillua may also be used as a standalone Lua library for obtaining syntax
highlighting information of source code snippets. Scintilla is not required in
that case.

[Lua]: https://lua.org
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[Scintilla]: https://scintilla.org

## Features

* Drop-in installation in most Scintilla environments -- no modifications to
  Scintilla are necessary.
* Support for [over 120][] programming languages.
* Easy lexer embedding for multi-language lexers.
* Universal color themes.
* Comparable speed to native Scintilla lexers.
* Can be used as a standalone Lua library (Scintilla is not required).

[over 120]: https://orbitalquark.github.io/scintillua/lexerlist.html

## Requirements

Scintillua requires Scintilla 4.4.5 or greater. The drop-in external lexer
already has Lua and LPeg are pre-compiled into it.

When used a standalone Lua library, Scintillua requires Lua 5.1 or greater and
[LPeg][] 1.0.0 or greater. Scintilla is not required.

[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/

## Download

Scintillua releases can be found [here][1]. A comprehensive list of changes
between releases can be found [here][2].

[1]: https://github.com/orbitalquark/scintillua/releases
[2]: https://orbitalquark.github.io/scintillua/changelog.html

## Installation and Usage

Scintillua comes with a [user manual][] in its *docs/* directory. It covers how
to drop Scintillua into an existing installation of a Scintilla-based
application, how to compile Scintillua into your Scintilla-based application,
and how to use Scintillua as a standalone Lua library.

As an example, you can drop Scintillua into an existing installation of
[SciTE][], the SCIntilla based Text Editor, by moving Scintillua's *lexers/*
directory into SciTE's installation directory, and then adding the following
to your *SciTEUser.properties* (Windows), *.SciTEUser.properties* (Linux), or
*SciTEGlobal.properties* (either) file:

    import lexers/lpeg

Scintillua's Application Programming Interface [(API) documentation][] is also
located in *docs/*. It provides information on how your Scintilla-based
application can utilize Scintillua and communicate with it, and also how to
write and utilize Lua lexers.

[user manual]: https://orbitalquark.github.io/scintillua/manual.html
[SciTE]: https://scintilla.org/SciTE.html
[(API) documentation]: https://orbitalquark.github.io/scintillua/api.html

## Compile

Scintillua can be built as an external Scintilla lexer, or it can be built
directly into a Scintilla-based application. The standalone Lua library does not
need to be compiled.

Scintillua currently only builds on Linux and BSD, though it can be
cross-compiled for Windows.

Requirements:

* [GNU C compiler][] (*gcc*) 7.1+ (circa mid-2017)
* [mingw-w64][] 5.0+ with GCC 7.1+ when cross-compiling for Windows.

In order to build the external lexer:

1. Place a copy of Scintilla in the root directory of Scintillua (the Scintilla
   directory should be called *scintilla/*).
2. Run `make` or `make win`.
3. The external lexer is either *lexers/liblexlpeg.so* or *lexers/LexLPeg.dll*.

For more information on compiling Scintillua, including how to compile
Scintillua directly into your Scintilla-based application please see the
[manual][].

[GNU C compiler]: https://gcc.gnu.org
[mingw-w64]: https://mingw-w64.org/
[manual]: https://orbitalquark.github.io/scintillua/manual.html#compiling-scintillua-directly-into-an-app

## Contribute

Scintillua is [open source][]. Feel free to submit new lexers, report bugs,
help, and discuss features either on the [mailing list][], or with me personally
(orbitalquark.att.triplequasar.com). Thanks to [everyone][] who has contributed.

[open source]: https://github.com/orbitalquark/scintillua
[mailing list]: https://foicica.com/lists
[everyone]: https://orbitalquark.github.io/scintillua/thanks.html
