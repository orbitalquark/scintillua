# Changelog

[Atom Feed][]

[Atom Feed]: feed

## 3.0.4-1 (11 Mar 2012)

Download:

* [Scintillua 3.0.4-1][]

Bugfixes:

* None.

Changes:

* Allow container styling.
* Updated VB and VBScript lexers.
* All new documentation in the `doc/` directory.

[Scintillua 3.0.4-1]: download/scintillua3.0.4-1.zip

## 3.0.3-1 (28 Jan 2012)

Download:

* [Scintillua 3.0.3-1][]

Bugfixes:

* Fixed bug in Matlab lexer for operators.

Changes:

* Removed unused Apache conf lexer.
* Updated D lexer.
* Added ChucK lexer.

[Scintillua 3.0.3-1]: download/scintillua3.0.3-1.zip

## 3.0.2-1 (08 Dec 2011)

Download:

* [Scintillua 3.0.2-1][]

Bugfixes:

* Detect and use Scala lexer.
* Fixed bug with folding line comments.
* Fixed multi-line delimited and token strings in D lexer.
* Detect and use XML lexer.
* Fixed highlighting of variables in Bash.

Changes:

* Added `l.REGEX` and `l.LABEL` [tokens][].
* All lexer `_tokenstyles` tables use standard styles.
* Removed `l.style_char` style.
* All new light and dark themes.
* Added Lua libraries and library functions to Lua lexer.
* Updated lexers and [API documentation][] to [Lua 5.2][].

[Scintillua 3.0.2-1]: download/scintillua3.0.2-1.zip
[tokens]: api/lexer.html#Tokens
[API documentation]: api/lexer.html
[Lua 5.2]: http://www.lua.org/manual/5.2/

## 3.0.0-1 (01 Nov 2011)

Download:

* [Scintillua 3.0.0-1][]

Bugfixes:

* None.

Changes:

* None.

[Scintillua 3.0.0-1]: download/scintillua3.0.0-1.zip

## 2.29-1 (19 Sep 2011)

Download:

* [Scintillua 2.29-1][]

Bugfixes:

* Fixed Lua long comment folding bug.
* Fixed a segfault when `props` is `null` (C++ containers).
* Fixed Markdown lexer styles.
* Fixed bug in folding single HTML/XML tags.
* Fixed some general bugs in folding.
* Fixed Scala symbol highlighting.

Changes:

* Updated Coffeescript lexer.
* Added HTML5 data attributes to HTML lexer.
* Multiple single-line comments can be folded with the `fold.line.comments`
  property set to 1.
* Added ConTeXt lexer.
* Updated LaTeX and TeX lexers.
* Added `l.style_embedded` to `themes/scite.lua` theme.

[Scintillua 2.29-1]: download/scintillua229-1.zip

## 2.27-1 (20 Jun 2011)

Download:

* [Scintillua 2.27-1][]

Bugfixes:

* Colors are now styled correctly in the Properties lexer.

Changes:

* Added Scala lexer.

[Scintillua 2.27-1]: download/scintillua227-1.zip

## 2.26 (10 Jun 2011)

Download:

* [Scintillua 2.26-1][]

Bugfixes:

* Fixed bug in `fold.by.indentation`.

Changes:

* [`get_style_at()`][] returns a string, not an integer.
* Added regex support for Coffeescript lexer.
* Embed Coffeescript lexer in HTML lexer.
* Writing custom folding for lexers is much [easier][] now.
* Added native folding for more than 60% of existing lexers. The rest still use
  folding by indentation by default.

[Scintillua 2.26-1]: download/scintillua226-1.zip
[`get_style_at()`]: api/lexer.html#get_style_at
[easier]: api/lexer.html#Simple.Code.Folding

## 2.25-1 (20 Mar 2011)

Download:

* [Scintillua 2.25-1][]

Bugfixes:

* LPeg lexer restores properly for SciTE.
* Fixed bug with nested embedded lexers.
* Re-init immediately upon setting `lexer.name` property.

Changes:

* Added primitive classes as types in Java lexer.
* Updated BibTeX lexer.
* Added Ruby on Rails lexer, use it instead of Ruby lexer in RHTML lexer.
* Updated `lpeg.properties` file with SciTE changes.

[Scintillua 2.25-1]: download/scintillua225-1.zip

## 2.24-1 (03 Feb 2011)

Download:

* [Scintillua 2.24-1][]

Bugfixes:

* Fixed comment bug in CAML lexer.

Changes:

* Added Markdown, BibTeX, CMake, CUDA, Desktop Entry, F#, GLSL, and Nemerle
  lexers.
* HTML lexer is more flexible.
* Update Lua functions and constants to Lua 5.1.

[Scintillua 2.24-1]: download/scintillua224-1.zip

## 2.23-1 (07 Dec 2010)

Download:

* [Scintillua 2.23-1][]

Bugfixes:

* Fixed bug in Tcl lexer with comments.

Changes:

* Renamed `MAC` flag to `OSX`.
* Removed unused Errorlist and Maxima lexers.

[Scintillua 2.23-1]: download/scintillua223-1.zip

## 2.22-1 (27 Oct 2010)

Download:

* [Scintillua 2.22-1][]

Bugfixes:

* Comments do not need to begin the line in Properties lexer.
* Fixed bug caused by not properly resetting styles.

Changes:

* Added coffeescript lexer.
* Updated D and Java lexers.
* Multi-language lexers are as fast as single language lexers.
* Added JSP lexer.
* Updated XML lexer.
* Scintillua can be dropped into a [SciTE][] install.

[Scintillua 2.22-1]: download/scintillua222-1.zip
[SciTE]: http://scintilla.org/SciTE.html

## 2.22-pre-1 (13 Sep 2010)

Download:

* [Scintillua 2.22-pre-1][]

Bugfixes:

* Do not crash if LexLPeg properties are not set correctly.

Changes:

* No need to modify parent [`_RULES`][] from child lexer.
* Renamed `lexers/ocaml.lua` to `lexers/caml.lua` and `lexers/postscript.lua` to
  `lexers/ps.lua` to conform to Scintilla names.

[Scintillua 2.22-pre-1]: download/scintillua222-pre-1.zip
[`_RULES`]: api/lexer.html#_RULES

## 2.21-1 (01 Sep 2010)

Bugfixes:

* Handle strings properly in Groovy and Vala lexers.

Changes:

* `LexLPeg.cxx` can be compiled as an external lexer.

## 2.20-1 (17 Aug 2010)

Download:

* [Scintillua 2.20-1][]

Bugfixes:

* Fixed bug with child's main lexer not having a `_tokenstyles` table.

Changes:

* Added Gtkrc, Prolog, and Go lexers.
* CSS lexer is more flexible.
* Diff lexer is more accurate.
* Updated TeX lexer.
* Only highlight C/C++ preprocessor words, not the whole line.
* Updated to [Scintilla][]/[SciTE][] 2.20.

[Scintillua 2.20-1]: download/scintillua220-1.zip
[Scintilla]: http://scintilla.org
[SciTE]: http://scintilla.org/SciTE.html

## 2.12-1 (15 Jun 2010)

Download:

* [Scintillua 2.12-1][]

Bugfixes:

* Differentiate between division and regex in Javascript lexer.

Changes:

* Added `enum` keyword to Java lexer.
* Updated D lexer.
* Updated to [Scintilla][]/[SciTE][] 2.12.

[Scintillua 2.12-1]: download/scintillua212-1.zip
[Scintilla]: http://scintilla.org
[SciTE]: http://scintilla.org/SciTE.html

## 2.11-1 (30 Apr 2010)

Download:

* [Scintillua 2.11-1][]

Bugfixes:

* Fixed bug in multi-language lexer detection.
* Close `lua_State` on lexer load error.
* Fixed bug with style metatables.
* Fixed bug with XML namespaces.
* Added Java annotations to Java lexer.

Changes:

* Updated Haskell lexer.
* Added Matlab/Octave lexer.
* Improve speed by using `SCI_GETCHARACTERPOINTER` instead of copying strings.
* Updated D lexer.
* Renamed `lexers/b.lua` to `lexers/b_lang.lua`and `lexers/r.lua` to
  `lexers/rstats.lua`.
* Allow multiple character escape sequences.
* Added Inform lexer.
* Added Lilypond and NSIS lexers.
* Updated LaTeX lexer.
* Updated to [Scintilla][]/[SciTE][] 2.11.

[Scintillua 2.11-1]: download/scintillua211-1.zip
[Scintilla]: http://scintilla.org
[SciTE]: http://scintilla.org/SciTE.html

## 2.03-1 (22 Feb 2010)

Download:

* [Scintillua 2.03-1][]

Bugfixes:

* Various bugfixes.
* Fixed bug with fonts for files open on command line.

Changes:

* Updated to [Scintilla][]/[SciTE][] 2.03.

[Scintillua 2.03-1]: download/scintillua203-1.zip
[Scintilla]: http://scintilla.org
[SciTE]: http://scintilla.org/SciTE.html

## 2.02-1 (26 Jan 2010)

Download:

* [Scintillua 2.02-1][]

Bugfixes:

* None.

Changes:

* Renamed `lexers/io.lua` to `lexers/Io.lua`.
* Rearranged tokens in various lexers for speed.
* Allow for [MinGW][] compilation on Windows.
* Call `ruby.LoadStyles()` from RHTML lexer.
* Updated to [Scintilla][]/[SciTE][] 2.02.

[Scintillua 2.02-1]: download/scintillua202-1.zip
[MinGW]: http://mingw.org
[Scintilla]: http://scintilla.org
[SciTE]: http://scintilla.org/SciTE.html

## 2.01-1 (13 Jan 2010)

* Initial release for [Scintilla][]/[SciTE][] 2.01.

[Scintilla]: http://scintilla.org
[SciTE]: http://scintilla.org/SciTE.html
