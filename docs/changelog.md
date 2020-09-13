## Changelog

### 4.4.5-1 (?)

Download:

* [Scintillua 4.4.5-1][]

Bugfixes:

* Fixed potential crashes if the lexer has not yet been fully initialized.

Changes:

* Deprecated `lexer.fold_line_comments()` in favor of
  [`lexer.fold_consecutive_lines()`][].
* Added `fold.line.groups` property and [`lexer.fold_line_groups`][] alias.
* Added 64-bit and 32-bit Windows DLLs.
* Added jq lexer.
* Updated to [Scintilla][]/[SciTE][] 4.4.5.

[Scintillua 4.4.5-1]: https://github.com/orbitalquark/scintillua/releases/download/scintillua_4.4.5-1/scintillua_4.4.5-1.zip
[`lexer.fold_consecutive_lines()`]: api.html#lexer.fold_consecutive_lines
[`lexer.fold_line_groups`]: api.html#lexer.fold_line_groups
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.21.0-1 (27 July 2020)

Download:

* Released in [Scintilla 3.21.0][]

Bugfixes:

* Fixed crash when *lexer.lua* cannot be found.
* Fixed assertion error when setting a style with no token.

Changes:

* Added [SCI\_GETNAMEDSTYLES][] for retrieving the style number associated with
  a style name.
* Added Fennel lexer.
* Updated Markdown lexer to handle code blocks and spans better.
* Added [`lexer.colors`][] and [`lexer.styles`][] tables for themes and lexers
  in order to have a more table-oriented approach to defining and using colors
  and styles.
* Deprecated `lexer.ascii`, `lexer.extend`, `lexer.cntrl`, `lexer.print`, and
  `lexer.nonnewline_esc` patterns.
* Alias [`lexer.fold*`][] to `lexer.property['fold*']`.
* Updated C lexer with C99 bool, true, and false.

[Scintilla 3.21.0]: https://sourceforge.net/projects/scintilla/files/scintilla/3.21.0/scintilla3210.zip/download
[SCI\_GETNAMEDSTYLES]: api.html#SCI_GETNAMEDSTYLES
[`lexer.colors`]: api.html#lexer.colors
[`lexer.styles`]: api.html#lexer.styles
[`lexer.fold*`]: api.html#lexer.folding

### 3.20.0-1 (9 May 2020)

Download:

* Released in [Scintilla 3.20.0][]

Bugfixes:

* Fixed incorrect grammar building for lexers that embed themselves.

Changes:

* Added txt2tags lexer.
* Always use string property values in themes.
* Updated Rust lexer.
* Style property settings are now case-sensitive.
* Lua state is safer, without requiring or giving access to the `io` and
  `package` modules.
* `lexer.lpeg.home` property can contain multiple paths separated by `;`.
* Added [SCI\_LOADLEXERLIBRARY][] for appending paths to `lexer.lpeg.home`.
* Added [SCI\_PROPERTYNAMES][] for retrieving a list of known lexer names.
* Implement Scintilla's `SCI_NAMEOFSTYLE` for retrieving style names. Retrieving
  by number via SCI\_PRIVATECALL is no longer supported.
* Switched to 1-based indices. The only 3rd party lexers affected are those
  implementing their own fold functions.
* Added [`lexer.range()`][] and [`lexer.to_eol()`][] convenience functions,
  replacing `lexer.delimited_range()`, `lexer.nested_pair()`, and
  `patt * lexer.nonnewline^0`.
* Added [`lexer.number`][] convenience pattern, replacing
  `lexer.float + lexer.integer`.

[Scintilla 3.20.0]: https://sourceforge.net/projects/scintilla/files/scintilla/3.20.0/scintilla3200.zip/download
[SCI\_LOADLEXERLIBRARY]: api.html#SCI_LOADLEXERLIBRARY
[SCI\_PROPERTYNAMES]: api.html#SCI_PROPERTYNAMES
[`lexer.range()`]: api.html#lexer.range
[`lexer.to_eol()`]: api.html#lexer.to_eol
[`lexer.number`]: api.html#lexer.number

### 3.11.1-1 (26 Oct 2019)

Download:

* Released in [Scintilla 3.11.1][]

Bugfixes:

* Prevent double-counting of fold points on a single line.

Changes:

* Updated Prolog, Logtalk, Rust, and C lexers.
* Added MediaWiki lexer.

[Scintilla 3.11.1]: https://sourceforge.net/projects/scintilla/files/scintilla/3.11.1/scintilla3111.zip/download

### 3.10.6-1 (11 Jun 2019)

Download:

* Released in [Scintilla 3.10.6][]

Bugfixes:

* None.

Changes:

* Updated Markdown lexer.
* Updated C++ lexer with support for quotes in C++14 integer literals.

[Scintilla 3.10.6]: https://sourceforge.net/projects/scintilla/files/scintilla/3.10.6/scintilla3106.zip/download

### 3.10.4-1 (17 Apr 2019)

Download:

* Released in [Scintilla 3.10.4][]

Bugfixes:

* Fixed lack of highlighting strings in YAML.

Changes:

* Added support for CSS3.

[Scintilla 3.10.4]: https://sourceforge.net/projects/scintilla/files/scintilla/3.10.4/scintilla3104.zip/download

### 3.10.3-1 (09 Mar 2019)

Download:

* Released in [Scintilla 3.10.3][]

Bugfixes:

* None.

Changes:

* Do not match '..' on the trailing end of `lexer.float`.
* Updated dmd lexer.

[Scintilla 3.10.3]: https://sourceforge.net/projects/scintilla/files/scintilla/3.10.3/scintilla3103.zip/download

### 3.10.2-1 (12 Jan 2019)

Download:

* Released in [Scintilla 3.10.2][]

Bugfixes:

* None.

Changes:

* Updated ConTeXt lexer.

[Scintilla 3.10.2]: https://sourceforge.net/projects/scintilla/files/scintilla/3.10.2/scintilla3102.zip/download

### 3.10.1-1 (31 Oct 2018)

Download:

* Released in [Scintilla 3.10.1][]

Bugfixes:

* None.

Changes:

* Updated ConTeXt and Markdown lexers.
* Improved HTML folding of traditionally single elements.
* Tweaked newline pattern to be more syntactically accurate.

[Scintilla 3.10.1]: https://sourceforge.net/projects/scintilla/files/scintilla/3.10.1/scintilla3101.zip/download

### 3.10.0-1 (30 Jun 2018)

Download:

* Released in [Scintilla 3.10.0][]

Bugfixes:

* Handle legacy `_fold` functions.
* Fixed child lexers that embed themselves into parents and fixed proxy lexers.
* Fixed incorrect highlighting of indented markdown lists.

Changes:

* Updated C# lexer.

[Scintilla 3.10.0]: https://sourceforge.net/projects/scintilla/files/scintilla/3.10.0/scintilla3100.zip/download

### 3.8.0-1 (28 Mar 2018)

Download:

* Released in [Scintilla 3.8.0][]

Bugfixes:

* Handle embedded JavaScript in other HTML-based languages like JSP.
* Fixed incorrectly applying style changes to stale property sets.

Changes:

* Renamed `lexer.LEXERPATH` to `lexer.path`.
* Added [`lexer.new()`][].
* Replaced `lexer._rules`, `lexer._tokenstyles`, and `lexer._foldsymbols` with
  [`lexer.add_rule()`][], [`lexer.add_style()`][], and
  [`lexer.add_fold_point()`][], respectively.
* Renamed `lexer.embed_lexer()` to [`lexer.embed()`][].
* Changed [`lexer.word_match()`][] arguments to accept a word string and
  case-sensitivity flag, eliminating word chars argument.
* Replaced `lexer._RULES[]` and `lexer._RULES[] =` with [`lexer.get_rule()`][]
  and [`lexer.modify_rule()`][], respectively.
* Refactored lexers to be more [object-oriented][]. Legacy lexers will still
  work, but it's recommended to [migrate them][].
* Updated lexer template.
* Added `fold.compact` property for folding trailing blank lines.

[Scintilla 3.8.0]: https://sourceforge.net/projects/scintilla/files/scintilla/3.8.0/scintilla380.zip/download
[`lexer.new()`]: api.html#lexer.new
[`lexer.add_rule()`]: api.html#lexer.add_rule
[`lexer.add_style()`]: api.html#lexer.add_style
[`lexer.add_fold_point()`]: api.html#lexer.add_fold_point
[`lexer.embed()`]: api.html#lexer.embed
[`lexer.word_match()`]: api.html#lexer.word_match
[`lexer.get_rule()`]: api.html#lexer.get_rule
[`lexer.modify_rule()`]: api.html#lexer.modify_rule
[object-oriented]: api.html#new-lexer-template
[migrate them]: api.html#migrating-legacy-lexers

### 3.7.5-1 (19 Aug 2017)

Download:

* [Scintillua 3.7.5-1][]

Bugfixes:

* None

Changes:

* Updated diff lexer, Forth, and Elixir lexers.
* Added Myrddin lexer.
* Updated themes to add `font` and `fontsize` properties.
* Updated to [Scintilla][]/[SciTE][] 3.7.5.

[Scintillua 3.7.5-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.7.5-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.7.4-1 (30 Apr 2017)

Download:

* [Scintillua 3.7.4-1][]

Bugfixes:

* Allow nested `{}` in Shell lexer variables.
* Fixed accidental editing of cached lexers.
* Fixed Moonscript file association.

Changes:

* Added rc, StandardML, and Logtalk lexers.
* Improved Scheme, ANSI C, Prolog, and Moonscript lexers.
* Updated to [Scintilla][]/[SciTE][] 3.7.4.

[Scintillua 3.7.4-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.7.4-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.7.3-1 (22 Feb 2017)

Download:

* [Scintillua 3.7.3-1][]

Bugfixes:

* Fixed child fold symbols not being copied to parent.
* Fixed detection of `</script>` even within a JavaScript comment.

Changes:

* Updated the JavaScript lexer.
* Applications can [query for lexer errors][].
* Updated to [Scintilla][]/[SciTE][] 3.7.3.

[Scintillua 3.7.3-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.7.3-1.zip
[query for lexer errors]: api.html#SCI_GETSTATUS
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.7.1-1 (05 Dec 2016)

Download:

* [Scintillua 3.7.1-1][]

Bugfixes:

* None.

Changes:

* Added [`lexer.STYLE_FOLDDISPLAYTEXT`][] style (`style.folddisplaytext` in
  themes) for fold display text.
* Updated to [Scintilla][]/[SciTE][] 3.7.1.

[Scintillua 3.7.1-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.7.1-1.zip
[`lexer.STYLE_FOLDDISPLAYTEXT`]: api.html#lexer.STYLE_FOLDDISPLAYTEXT
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.7.0-1 (19 Oct 2016)

Download:

* [Scintillua 3.7.0-1][]

Bugfixes:

* Throw an error if a lexer cannot be loaded or has errors.
* Improved [`lexer.float`][] pattern.
* Handle lexers with no rules/grammars gracefully.
* Fixed bug in [`lexer.property_int`][] not returning a number in all cases.

Changes:

* Added `_foldsymbols._case_insensitive` option.
* Added Protobuf and Crystal lexers.
* Updated PKGBUILD lexer.
* Updated to [Scintilla][]/[SciTE][] 3.7.0.

[Scintillua 3.7.0-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.7.0-1.zip
[`lexer.float`]: api.html#lexer.float
[`lexer.property_int`]: api.html#lexer.property_int
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.6.7-1 (15 Sep 2016)

Download:

* [Scintillua 3.6.7-1][]

Bugfixes:

* Fixed some compiler warnings.

Changes:

* Added TaskPaper lexer.
* Updated to [Scintilla][]/[SciTE][] 3.6.7.

[Scintillua 3.6.7-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.6.7-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.6.5-1 (26 Apr 2016)

Download:

* [Scintillua 3.6.5-1][]

Bugfixes:

* None.

Changes:

* Updated some documentation for clarity.
* Updated to [Scintilla][]/[SciTE][] 3.6.5.

[Scintillua 3.6.5-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.6.5-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.6.4-2 (04 Apr 2016)

Download:

* [Scintillua 3.6.4-2][]

Bugfixes:

* Fixed bug with loading default themes in 3.6.4-1.

Changes:

* Themes must `require('lexer')` now (if they are not already), and cannot rely
  on `lexer` to be globally defined. **This is a breaking change.**

[Scintillua 3.6.4-2]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.6.4-2.zip

### 3.6.4-1 (19 Mar 2016)

Download:

* [Scintillua 3.6.4-1][]

Bugfixes:

* Fixed potential crash with malformed styles.
* Fixed string highlighting in Rexx.

Changes:

* Recognize `weight` [style property][].
* Added [`lexer.line_state`][] and [`lexer.line_from_position()`][] for
  [stateful lexers][].
* Updated Elixir and JavaScript lexers.
* Updated to [Scintilla][]/[SciTE][] 3.6.4.

[Scintillua 3.6.4-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.6.4-1.zip
[style property]: api.html#styles-and-styling
[`lexer.line_state`]: api.html#lexer.line_state
[`lexer.line_from_position()`]: api.html#lexer.line_from_position
[stateful lexers]: api.html#lexers-with-complex-state
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.6.3-1 (23 Jan 2016)

Download:

* [Scintillua 3.6.3-1][]

Bugfixes:

* Fixed bug in Rexx lexer with identifiers.

Changes:

* Added SNOBOL4, Icon, AutoIt, APL, Faust, Ledger, man/roff, Pure, Dockerfile,
  MoonScript, and PICO-8 lexers.
* Updated Elixir lexer.
* Updated to [Scintilla][]/[SciTE][] 3.6.3.

[Scintillua 3.6.3-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.6.3-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.6.2-1 (07 Nov 2015)

Download:

* [Scintillua 3.6.2-1][]

Bugfixes:

* None.

Changes:

* Added Gherkin lexer.
* Updated to [Scintilla][]/[SciTE][] 3.6.2.
* Updated to [LPeg][] 1.0.0.

[Scintillua 3.6.2-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.6.2-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html

### 3.6.1-1 (15 Sep 2015)

Download:

* [Scintillua 3.6.1-1][]

Bugfixes:

* Fixed Markdown lexer bugs and corner-cases.
* Fixed multiple key highlighting on a single YAML line.

Changes:

* Updated to [Scintilla][]/[SciTE][] 3.6.1.

[Scintillua 3.6.1-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.6.1-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.6.0-1 (03 Aug 2015)

Download:

* [Scintillua 3.6.0-1][]

Bugfixes:

* None.

Changes:

* Improved performance in some scripting-language lexers.
* Updated Python lexer.
* Updated to [Scintilla][]/[SciTE][] 3.6.0.

[Scintillua 3.6.0-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.6.0-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.5.7-1 (23 Jun 2015)

Download:

* [Scintillua 3.5.7-1][]

Bugfixes:

* None.

Changes:

* Added Windows Script File lexer.
* Updated to [Scintilla][]/[SciTE][] 3.5.7.

[Scintillua 3.5.7-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.5.7-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.5.6-1 (26 May 2015)

Download:

* [Scintillua 3.5.6-1][]

Bugfixes:

* Fixed ASP, Applescript, and Perl lexers.
* Fixed segfault in parsing some instances of style definitions.

Changes:

* Added Elixir lexer.
* Updated to [Scintilla][]/[SciTE][] 3.5.6.

[Scintillua 3.5.6-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.5.6-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.5.5-1 (18 Apr 2015)

Download:

* [Scintillua 3.5.5-1][]

Bugfixes:

* Fixed Perl lexer corner-case.
* VB lexer keywords are case-insensitive now.

Changes:

* Renamed Nimrod lexer to Nim.
* Added Rust lexer.
* Added TOML lexer.
* Lexers that fold by indentation should make use of [`_FOLDBYINDENTATION`][]
  field now.
* Added PowerShell lexer.
* Updated to [Scintilla][]/[SciTE][] 3.5.5.

[Scintillua 3.5.5-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.5.5-1.zip
[`_FOLDBYINDENTATION`]: api.html#fold-by-indentation
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.5.4-1 (09 Mar 2015)

Download:

* [Scintillua 3.5.4-1][]

Bugfixes:

* Improved `fold.by.indentation`.

Changes:

* Updated PHP and Python lexers.
* Added Fish lexer.
* Removed extinct B lexer.
* Updated to [LPeg][] 0.12.2.
* Updated to [Scintilla][]/[SciTE][] 3.5.4.

[Scintillua 3.5.4-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.5.4-1.zip
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.5.3-1 (20 Jan 2015)

Download:

* [Scintillua 3.5.3-1][]

Bugfixes:

* Fixed bug in overwriting fold levels set by custom fold functions.

Changes:

* Added vCard and Texinfo lexers.
* Updates to allow Scintillua to be compiled against Lua 5.3.
* Updated Lua lexer for Lua 5.3.
* Updated to [Scintilla][]/[SciTE][] 3.5.3.

[Scintillua 3.5.3-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.5.3-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.5.2-1 (10 Dec 2014)

Download:

* [Scintillua 3.5.2-1][]

Bugfixes:

* Improved folding by indentation.

Changes:

* Updated Tcl lexer.
* Added `fold.on.zero.sum.line` property for folding on `} else {`-style lines.
* Updated to [Scintilla][]/[SciTE][] 3.5.2.

[Scintillua 3.5.2-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.5.2-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.5.1-1 (01 Oct 2014)

Download:

* [Scintillua 3.5.1-1][]

Bugfixes:

* None.

Changes:

* Added Xtend lexer.
* Improved performance for lexers with no grammars and no fold rules.
* Updated to [Scintilla][]/[SciTE][] 3.5.1.

[Scintillua 3.5.1-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.5.1-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.5.0-1 (01 Sep 2014)

Download:

* [Scintillua 3.5.0-1][]

Bugfixes:

* None.

Changes:

* Updated to [LPeg][] 0.12.
* Updated to [Scintilla][]/[SciTE][] 3.5.0.

[Scintillua 3.5.0-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.5.0-1.zip
[LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.4.4-1 (04 Jul 2014)

Download:

* [Scintillua 3.4.4-1][]

Bugfixes:

* Fixed cases of incorrect Markdown header highlighting.
* Fixed some folding by indentation edge cases.
* Fixed `#RRGGBB` color interpretation for styles.
* Fixed Bash heredoc highlighting.

Changes:

* Added reST and YAML lexers.
* Updated D lexer.
* Updated to [Scintilla][]/[SciTE][] 3.4.4.

[Scintillua 3.4.4-1]: https://github.com/orbitalquark/scintillua/archive/scintillua_3.4.4-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 3.3.9-1 (05 Feb 2014)

Download:

* [Scintillua 3.3.9-1][]

Bugfixes:

* None.

Changes:

* Updated HTML, LaTeX, and Go lexers.
* Enable Scintillua to be used as a stand-alone [Lua library][].
* Scintillua can accept and use [external Lua states][].

[Scintillua 3.3.9-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.3.9-1.zip
[Lua library]: manual.html#using-scintillua-as-a-lua-library
[external Lua states]: api.html#SCI_CHANGELEXERSTATE

### 3.3.7-1 (21 Dec 2013)

Scintillua 3.3.7-1 is a major change from 3.3.2-1. It has a completely new
[theme implementation][] and many lexer structure and API changes. Custom lexers
and themes will need to be updated.

Download:

* [Scintillua 3.3.7-1][]

Bugfixes:

* Ensure the default style is not considered a whitespace style in
  multi-language lexers.
* Fixed occasional crash when getting the lexer name in a multi-language lexer.
* Disable folding when `fold` property is `0`.
* HTML and XML lexers maintain their states better.
* Fixed slowdown in processing long lines for folding.
* Fixed slowdown with large HTML files.

Changes:

* Completely new [theme implementation][]; removed `lexer.style()` and
  `lexer.color()` functions.
* Changed [`lexer._tokenstyles`][] to be a map instead of a list.
* Changed `lexer.get_fold_level()`, `lexer.get_indent_amount()`,
  `lexer.get_property()`, and `lexer.get_style_at()` functions to be
  [`lexer.fold_level`][], [`lexer.indent_amount`][], [`lexer.property`][], and
  [`lexer.style_at`][] tables, respectively.
* Added [`lexer.property_int`][] and [`lexer.property_expanded`][] tables.
* Changed API for `lexer.delimited_range()` and `lexer.nested_pair()`.
* Only enable `fold.by.indentation` property by default in
  whitespace-significant languages.
* Updated D lexer.
* Added Nimrod lexer.
* Added additional parameter to [`lexer.load()`][] to allow child lexers to be
  embedded multiple times with different start/end tokens.
* Lexers do not need an "any\_char" [rule][] anymore; it is included by default.
* [Child lexers][] do not need an explicit `M._lexer = parent` declaration
  anymore; it is done automatically.
* Added NASM Assembly lexer.
* Separated C/C++ lexer into ANSI C and C++ lexers.
* Added Dart lexer.
* Renamed "hypertext" and "Io" lexers to "html" and "io\_lang" internally.

[theme implementation]: api.html#styles-and-styling
[Scintillua 3.3.7-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.3.7-1.zip
[`lexer._tokenstyles`]: api.html#token-styles
[`lexer.fold_level`]: api.html#lexer.fold_level
[`lexer.indent_amount`]: api.html#lexer.indent_amount
[`lexer.property`]: api.html#lexer.property
[`lexer.style_at`]: api.html#lexer.style_at
[`lexer.property_int`]: api.html#lexer.property_int
[`lexer.property_expanded`]: api.html#lexer.property_expanded
[`lexer.load()`]: api.html#lexer.load
[rule]: api.html#rules
[Child lexers]: api.html#child-lexer

### 3.3.2-1 (25 May 2013)

Download:

* [Scintillua 3.3.2-1][]

Bugfixes:

* None.

Changes:

* No need for '!' in front of font faces in GTK anymore.
* Scintillua supports multiple curses platforms, not just ncurses.
* [SCI\_GETLEXERLANGUAGE][] returns "lexer/current" for multi-lang lexers.
* Updated D lexer.

[Scintillua 3.3.2-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.3.2-1.zip
[SCI\_GETLEXERLANGUAGE]: api.html#SCI_GETLEXERLANGUAGE

### 3.3.0-1 (31 Mar 2013)

Download:

* [Scintillua 3.3.0-1][]

Bugfixes:

* Fixed crash when attempting to load a non-existant lexer.
* Fixed CSS preprocessor styling.

Changes:

* Added Less, Literal Coffeescript, and Sass lexers.

[Scintillua 3.3.0-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.3.0-1.zip

### 3.2.4-1 (18 Jan 2013)

Download:

* [Scintillua 3.2.4-1][]

Bugfixes:

* Fixed some operators in Bash lexer.

Changes:

* Rewrote Makefile lexer.
* Rewrote documentation.
* Improved speed and memory usage of lexers.

[Scintillua 3.2.4-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.2.4-1.zip

### 3.2.3-1 (22 Oct 2012)

Download:

* [Scintillua 3.2.3-1][]

Bugfixes:

* Include `_` as identifier char in Desktop lexer.

Changes:

* Copied `container` lexer to a new `text` lexer for containers that prefer to
  use the latter.
* Added SciTE usage note on themes.

[Scintillua 3.2.3-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.2.3-1.zip

### 3.2.2-1 (31 Aug 2012)

Download:

* [Scintillua 3.2.2-1][]

Bugfixes:

* Fixed bug with `$$` variables in Perl lexer.

Changes:

* Added support for ncurses via [scinterm][].
* Added `__DATA__` and `__END__` markers to Perl lexer.
* Added new [`lexer.last_char_includes()`][] function for better regex
  detection.
* Updated AWK lexer.

[Scintillua 3.2.2-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.2.2-1.zip
[scinterm]: https://orbitalquark.github.io/scinterm
[`lexer.last_char_includes()`]: api.html#lexer.last_char_includes

### 3.2.1-1 (15 Jul 2012)

Download:

* [Scintillua 3.2.1-1][]

Bugfixes:

* None.

Changes:

* Updated AWK lexer.
* Updated HTML lexer to recognize HTML5 'script' and 'style' tags.

[Scintillua 3.2.1-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.2.1-1.zip

### 3.2.0-1 (01 Jun 2012)

Download:

* [Scintillua 3.2.0-1][]

Bugfixes:

* Fixed bug with SciTE italic and underlined style properties.

Changes:

* Identify more file extensions.
* Updated Batch lexer.

[Scintillua 3.2.0-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.2.0-1.zip

### 3.1.0-1 (23 Apr 2012)

Download:

* [Scintillua 3.1.0-1][]

Bugfixes:

* Fixed bug with Python lexer identification in SciTE.

Changes:

* Improved the speed of simple code folding.
* Check for lexer grammar before lexing.

[Scintillua 3.1.0-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.1.0-1.zip

### 3.0.4-1 (11 Mar 2012)

Download:

* [Scintillua 3.0.4-1][]

Bugfixes:

* None.

Changes:

* Allow container styling.
* Updated VB and VBScript lexers.
* All new documentation in the `doc/` directory.

[Scintillua 3.0.4-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.0.4-1.zip

### 3.0.3-1 (28 Jan 2012)

Download:

* [Scintillua 3.0.3-1][]

Bugfixes:

* Fixed bug in Matlab lexer for operators.

Changes:

* Removed unused Apache conf lexer.
* Updated D lexer.
* Added ChucK lexer.

[Scintillua 3.0.3-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.0.3-1.zip

### 3.0.2-1 (08 Dec 2011)

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

[Scintillua 3.0.2-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.0.2-1.zip
[tokens]: api.html#tokens
[API documentation]: api.html#lexer
[Lua 5.2]: https://www.lua.org/manual/5.2/

### 3.0.0-1 (01 Nov 2011)

Download:

* [Scintillua 3.0.0-1][]

Bugfixes:

* None.

Changes:

* None.

[Scintillua 3.0.0-1]: https://github.com/orbitalquark/scintillua/archive/scintillua3.0.0-1.zip

### 2.29-1 (19 Sep 2011)

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

[Scintillua 2.29-1]: https://github.com/orbitalquark/scintillua/archive/scintillua229-1.zip

### 2.27-1 (20 Jun 2011)

Download:

* [Scintillua 2.27-1][]

Bugfixes:

* Colors are now styled correctly in the Properties lexer.

Changes:

* Added Scala lexer.

[Scintillua 2.27-1]: https://github.com/orbitalquark/scintillua/archive/scintillua227-1.zip

### 2.26-1 (10 Jun 2011)

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

[Scintillua 2.26-1]: https://github.com/orbitalquark/scintillua/archive/scintillua226-1.zip
[`get_style_at()`]: api.html#lexer.style_at
[easier]: api.html#code-folding

### 2.25-1 (20 Mar 2011)

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

[Scintillua 2.25-1]: https://github.com/orbitalquark/scintillua/archive/scintillua225-1.zip

### 2.24-1 (03 Feb 2011)

Download:

* [Scintillua 2.24-1][]

Bugfixes:

* Fixed comment bug in CAML lexer.

Changes:

* Added Markdown, BibTeX, CMake, CUDA, Desktop Entry, F#, GLSL, and Nemerle
  lexers.
* HTML lexer is more flexible.
* Update Lua functions and constants to Lua 5.1.

[Scintillua 2.24-1]: https://github.com/orbitalquark/scintillua/archive/scintillua224-1.zip

### 2.23-1 (07 Dec 2010)

Download:

* [Scintillua 2.23-1][]

Bugfixes:

* Fixed bug in Tcl lexer with comments.

Changes:

* Renamed `MAC` flag to `OSX`.
* Removed unused Errorlist and Maxima lexers.

[Scintillua 2.23-1]: https://github.com/orbitalquark/scintillua/archive/scintillua223-1.zip

### 2.22-1 (27 Oct 2010)

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

[Scintillua 2.22-1]: https://github.com/orbitalquark/scintillua/archive/scintillua222-1.zip
[SciTE]: https://scintilla.org/SciTE.html

### 2.22-pre-1 (13 Sep 2010)

Download:

* [Scintillua 2.22-pre-1][]

Bugfixes:

* Do not crash if LexLPeg properties are not set correctly.

Changes:

* No need to modify parent `_RULES` from child lexer.
* Renamed `lexers/ocaml.lua` to `lexers/caml.lua` and `lexers/postscript.lua` to
  `lexers/ps.lua` to conform to Scintilla names.

[Scintillua 2.22-pre-1]: https://github.com/orbitalquark/scintillua/archive/scintillua222-pre-1.zip

### 2.21-1 (01 Sep 2010)

Bugfixes:

* Handle strings properly in Groovy and Vala lexers.

Changes:

* `LexLPeg.cxx` can be compiled as an external lexer.

### 2.20-1 (17 Aug 2010)

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

[Scintillua 2.20-1]: https://github.com/orbitalquark/scintillua/archive/scintillua220-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 2.12-1 (15 Jun 2010)

Download:

* [Scintillua 2.12-1][]

Bugfixes:

* Differentiate between division and regex in Javascript lexer.

Changes:

* Added `enum` keyword to Java lexer.
* Updated D lexer.
* Updated to [Scintilla][]/[SciTE][] 2.12.

[Scintillua 2.12-1]: https://github.com/orbitalquark/scintillua/archive/scintillua212-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 2.11-1 (30 Apr 2010)

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

[Scintillua 2.11-1]: https://github.com/orbitalquark/scintillua/archive/scintillua211-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 2.03-1 (22 Feb 2010)

Download:

* [Scintillua 2.03-1][]

Bugfixes:

* Various bugfixes.
* Fixed bug with fonts for files open on command line.

Changes:

* Updated to [Scintilla][]/[SciTE][] 2.03.

[Scintillua 2.03-1]: https://github.com/orbitalquark/scintillua/archive/scintillua203-1.zip
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 2.02-1 (26 Jan 2010)

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

[Scintillua 2.02-1]: https://github.com/orbitalquark/scintillua/archive/scintillua202-1.zip
[MinGW]: http://mingw.org
[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html

### 2.01-1 (13 Jan 2010)

* Initial release for [Scintilla][]/[SciTE][] 2.01.

[Scintilla]: https://scintilla.org
[SciTE]: https://scintilla.org/SciTE.html
