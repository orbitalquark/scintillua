# Scintillua

Scintillua enables lexers for [Scintilla][] to be written in the [Lua][] programming language,
particularly in conjunction with the [LPeg][] pattern-matching library. It is the quickest way
to add new or customized syntax highlighting and code folding for programming languages to any
Scintilla-based text editor or IDE. Scintillua was designed to be dropped into or compiled with
any Scintilla environment.

Scintillua may also be used as a standalone Lua library for obtaining syntax highlighting
information of source code. Scintilla is not required in that case.

[Lua]: https://lua.org
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[Scintilla]: https://scintilla.org

## Features

- Drop-in installation in most Scintilla environments -- no modifications to Scintilla are
	necessary.
- Support for [over 120][] programming languages.
- Easy lexer embedding for multi-language lexers.
- Universal color themes.
- Comparable speed to native Scintilla/Lexilla lexers.
- Can be used as a standalone Lua library (Scintilla is not required).

[over 120]: lexerlist.md

## Requirements

Scintillua requires Scintilla 5.0.1 or greater and [Lexilla][] 5.1.0 or greater for a drop-in
installation. The drop-in external lexer already has Lua and LPeg pre-compiled into it.

When used as a standalone Lua library, Scintillua requires Lua 5.1 or greater and [LPeg][]
1.0.0 or greater. Scintilla is not required.

[Lexilla]: https://www.scintilla.org/Lexilla.html
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/

## Download

Scintillua releases can be found [here][1]. A comprehensive list of changes between releases
can be found [here][2].

[1]: https://github.com/orbitalquark/scintillua/releases
[2]: changelog.md

## Installation and Usage

Scintillua comes with a [user manual][] in its *docs/* directory. It covers how to drop Scintillua
into an existing installation of a Scintilla-based application, how to compile Scintillua into
your Scintilla-based application, and how to use Scintillua as a standalone Lua library.

As an example, you can drop Scintillua into an existing installation of [SciTE][], the SCIntilla
based Text Editor, by moving Scintillua's directory into SciTE's installation directory,
renaming it simply *scintillua*, and then adding the following to your *SciTEGlobal.properties*
file:

	import scintillua/scintillua

Scintillua's Application Programming Interface [(API) documentation][] is also located in
*docs/*. It provides information on how to write and utilize Lua lexers.

[user manual]: manual.md
[SciTE]: https://scintilla.org/SciTE.html
[(API) documentation]: api.md

## Compile

Scintillua can be built as an external Scintilla lexer, or it can be built directly into a
Scintilla-based application. The standalone Lua library does not need to be compiled.

Scintillua can be built on Windows and Linux using [CMake][].

General requirements:

- [CMake][] 3.16+
- A C and C++ compiler, such as:
	- [GNU C compiler][] (*gcc*) 7.1+
	- [Microsoft Visual Studio][] 2019+

Basic procedure:

1. Configure CMake to build Scintillua by pointing it to Scintillua's source directory (where
	*CMakeLists.txt* is) and specifying a binary directory to compile to.
2. Build Scintillua.
3. Either copy the built shared object library to Scintillua's *lexers/* directory or use CMake to
	install it there.

For example:

```bash
cmake -S . -B build_dir -D CMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build_dir -j # compiled shared object library is in build_dir/
cmake --install build_dir # installs the shared object library to the local lexers/ directory
```

For more information on compiling Scintillua, including how to compile Scintillua directly into
your Scintilla-based application please see the [manual][].

[CMake]: https://cmake.org
[GNU C compiler]: https://gcc.gnu.org
[Microsoft Visual Studio]: https://visualstudio.microsoft.com/
[manual]: manual.md#compiling-scintillua-directly-into-an-app

## Support

- [Manual](manual.md)
- [API Documentation](api.md)
- [Project page](https://github.com/orbitalquark/scintillua)
- [Issue tracker](https://github.com/orbitalquark/scintillua/issues)
- [Discussions](https://github.com/orbitalquark/scintillua/discussions)
- [Credits](thanks.md)

You can contact me personally at code att foicica.com.
