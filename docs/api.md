## Scintillua API Documentation

1. [Scintillua](#Scintillua)
1. [lexer](#lexer)
- - -

### Overview

The Scintillua Scintilla lexer has its own API in order to avoid any
modifications to Scintilla itself. It is invoked using
[`SCI_PRIVATELEXERCALL`][]. Please note that some of the names of the API
calls do not make perfect sense. This is a tradeoff in order to keep
Scintilla unmodified.

[`SCI_PRIVATELEXERCALL`]: http://scintilla.org/ScintillaDoc.html#LexerObjects

The following notation is used:

    SCI_PRIVATELEXERCALL (int operation, void *pointer)

This means you would call Scintilla like this:

    SendScintilla(sci, SCI_PRIVATELEXERCALL, operation, pointer);


<a id="Scintillua.Scintillua.Usage.Example"></a>

### Scintillua Usage Example

Here is a pseudo-code example:

    init_app() {
      SetLibraryProperty("lpeg.home", "/home/mitchell/app/lexers")
      SetLibraryProperty("lpeg.color.theme", "light")
      sci = scintilla_new()
    }

    create_doc() {
      doc = SendScintilla(sci, SCI_CREATEDOCUMENT)
      SendScintilla(sci, SCI_SETDOCPOINTER, 0, doc)
      SendScintilla(sci, SCI_SETILEXER, 0, CreateLexer(NULL))
      fn = SendScintilla(sci, SCI_GETDIRECTFUNCTION)
      SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_GETDIRECTFUNCTION, fn)
      psci = SendScintilla(sci, SCI_GETDIRECTPOINTER)
      SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_SETDOCPOINTER, psci)
      SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_SETLEXERLANGUAGE, "lua")
    }

    set_lexer(lang) {
      psci = SendScintilla(sci, SCI_GETDIRECTPOINTER)
      SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_SETDOCPOINTER, psci)
      SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_SETLEXERLANGUAGE, lang)
    }

### Functions defined by `Scintillua`

<a id="SCI_CHANGELEXERSTATE"></a>
#### `SCI_PRIVATELEXERCALL`(SCI\_CHANGELEXERSTATE, lua)

Tells Scintillua to use `lua` as its Lua state instead of creating a separate
state.

`lua` must have already opened the "base", "string", "table", and "lpeg"
libraries.

Scintillua will create a single `lexer` package (that can be used with Lua's
`require()`), as well as a number of other variables in the
`LUA_REGISTRYINDEX` table with the "sci_" prefix.

Instead of including the path to Scintillua's lexers in the `package.path` of
the given Lua state, set the "lexer.lpeg.home" property appropriately
instead. Scintillua uses that property to find and load lexers.

Fields:

* `SCI_CHANGELEXERSTATE`: 
* `lua`: (`lua_State *`) The Lua state to use.

Usage:

* `lua = luaL_newstate()`
* `SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_CHANGELEXERSTATE, lua)`

<a id="SCI_GETDIRECTFUNCTION"></a>
#### `SCI_PRIVATELEXERCALL`(SCI\_GETDIRECTFUNCTION, SciFnDirect)

Tells Scintillua the address of the function that handles Scintilla messages.

Despite the name `SCI_GETDIRECTFUNCTION`, it only notifies Scintillua what
the value of `SciFnDirect` obtained from [`SCI_GETDIRECTFUNCTION`][] is. It
does not return anything.
Use this if you would like to have the Scintillua lexer set all Lua LPeg
lexer styles automatically. This is useful for maintaining a consistent color
theme. Do not use this if your application maintains its own color theme.

If you use this call, it *must* be made *once* for each Scintilla buffer that
was created using [`SCI_CREATEDOCUMENT`][]. You must also use the
[`SCI_SETDOCPOINTER()`](#SCI_SETDOCPOINTER) Scintillua API call.

[`SCI_GETDIRECTFUNCTION`]: http://scintilla.org/ScintillaDoc.html#SCI_GETDIRECTFUNCTION
[`SCI_CREATEDOCUMENT`]: http://scintilla.org/ScintillaDoc.html#SCI_CREATEDOCUMENT

Fields:

* `SCI_GETDIRECTFUNCTION`: 
* `SciFnDirect`: The pointer returned by [`SCI_GETDIRECTFUNCTION`][].

Usage:

* `fn = SendScintilla(sci, SCI_GETDIRECTFUNCTION)`
* `SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_GETDIRECTFUNCTION, fn)`

See also:

* [`SCI_SETDOCPOINTER`](#SCI_SETDOCPOINTER)

<a id="SCI_GETLEXERLANGUAGE"></a>
#### `SCI_PRIVATELEXERCALL`(SCI\_GETLEXERLANGUAGE, languageName)

Returns the length of the string name of the current Lua LPeg lexer or stores
the name into the given buffer. If the buffer is long enough, the name is
terminated by a `0` character.

For parent lexers with embedded children or child lexers embedded into
parents, the name is in "lexer/current" format, where "lexer" is the actual
lexer's name and "current" is the parent or child lexer at the current caret
position. In order for this to work, you must have called
[`SCI_GETDIRECTFUNCTION`](#SCI_GETDIRECTFUNCTION) and
[`SCI_SETDOCPOINTER`](#SCI_SETDOCPOINTER).

Fields:

* `SCI_GETLEXERLANGUAGE`: 
* `languageName`: (`char *`) If `NULL`, returns the length that should be
  allocated to store the string Lua LPeg lexer name. Otherwise fills the
  buffer with the name.

<a id="SCI_GETNAMEDSTYLES"></a>
#### `SCI_PRIVATELEXERCALL`(SCI\_GETNAMEDSTYLES, styleName)

Returns the style number associated with *styleName*, or `STYLE_DEFAULT`
if *styleName* is not known.

Fields:

* `SCI_GETNAMEDSTYLES`: 
* `styleName`: (`const char *`) Style name to get the style number of.

Usage:

* `SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_GETNAMEDSTYLES, "error")`
* `SendScintilla(sci, SCI_ANNOTATIONSETSTYLE, line, style) // match error
  style`

<a id="SCI_GETSTATUS"></a>
#### `SCI_PRIVATELEXERCALL`(SCI\_GETSTATUS)

Returns the error message of the Scintillua or Lua LPeg lexer error that
occurred (if any).

If no error occurred, the returned message will be empty.

Since Scintillua does not throw errors as they occur, errors can only be
handled passively. Note that Scintillua does print all errors to stderr.

Fields:

* `SCI_GETSTATUS`: 

Usage:

* `SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_GETSTATUS, errmsg)`
* `if (strlen(errmsg) > 0) { /* handle error */ }`

<a id="SCI_LOADLEXERLIBRARY"></a>
#### `SCI_PRIVATELEXERCALL`(SCI\_LOADLEXERLIBRARY, path)

Tells Scintillua that the given path is where Scintillua's lexers are
located, or is a path that contains additional lexers and/or themes to load
(e.g. user-defined lexers/themes).

This call may be made multiple times in order to support lexers and themes
across multiple directories.

Fields:

* `SCI_LOADLEXERLIBRARY`: 
* `path`: (`const char *`) A path containing Scintillua lexers and/or
  themes.

Usage:

* `SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_LOADLEXERLIBRARY,
  "path/to/lexers")`

<a id="SCI_PROPERTYNAMES"></a>
#### `SCI_PRIVATELEXERCALL`(SCI\_PROPERTYNAMES, names)

Returns the length of a '\n'-separated list of known lexer names, or stores
the lexer list into the given buffer. If the buffer is long enough, the
string is terminated by a `0` character.

The lexers in this list can be passed to the
[`SCI_SETLEXERLANGUAGE`](#SCI_SETLEXERLANGUAGE) Scintillua API call.

Fields:

* `SCI_PROPERTYNAMES`: 
* `names`: (`char *`) If `NULL`, returns the length that should be
  allocated to store the list of lexer names. Otherwise fills the buffer with
  the names.

Usage:

* `SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_PROPERTYNAMES, lexers)`
* `// lexers now contains a '\n'-separated list of known lexer names`

See also:

* [`SCI_SETLEXERLANGUAGE`](#SCI_SETLEXERLANGUAGE)

<a id="SCI_SETDOCPOINTER"></a>
#### `SCI_PRIVATELEXERCALL`(SCI\_SETDOCPOINTER, sci)

Tells Scintillua the address of the Scintilla window currently in use.

Despite the name `SCI_SETDOCPOINTER`, it has no relationship to Scintilla
documents.

Use this call only if you are using the
[`SCI_GETDIRECTFUNCTION()`](#SCI_GETDIRECTFUNCTION) Scintillua API call. It
*must* be made *before* each call to the
[`SCI_SETLEXERLANGUAGE()`](#SCI_SETLEXERLANGUAGE) Scintillua API call.

Fields:

* `SCI_SETDOCPOINTER`: 
* `sci`: The pointer returned by [`SCI_GETDIRECTPOINTER`][].

[`SCI_GETDIRECTPOINTER`]: http://scintilla.org/ScintillaDoc.html#SCI_GETDIRECTPOINTER

Usage:

* `SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_SETDOCPOINTER, sci)`

See also:

* [`SCI_GETDIRECTFUNCTION`](#SCI_GETDIRECTFUNCTION)
* [`SCI_SETLEXERLANGUAGE`](#SCI_SETLEXERLANGUAGE)

<a id="SCI_SETLEXERLANGUAGE"></a>
#### `SCI_PRIVATELEXERCALL`(SCI\_SETLEXERLANGUAGE, languageName)

Sets the current Lua LPeg lexer to `languageName`.

If you are having the Scintillua lexer set the Lua LPeg lexer styles
automatically, make sure you call the
[`SCI_SETDOCPOINTER()`](#SCI_SETDOCPOINTER) Scintillua API *first*.

Fields:

* `SCI_SETLEXERLANGUAGE`: 
* `languageName`: (`const char*`) The name of the Lua LPeg lexer to use.

Usage:

* `SendScintilla(sci, SCI_PRIVATELEXERCALL, SCI_SETLEXERLANGUAGE, "lua")`

See also:

* [`SCI_SETDOCPOINTER`](#SCI_SETDOCPOINTER)
* [`SCI_PROPERTYNAMES`](#SCI_PROPERTYNAMES)

<a id="styleNum"></a>
#### `SCI_PRIVATELEXERCALL`(styleNum, style)

Returns the length of the associated SciTE-formatted style definition for the
given style number or stores that string into the given buffer. If the buffer
is long enough, the string is terminated by a `0` character.

Please see the [SciTE documentation][] for the style definition format
specified by `style.*.stylenumber`. You can parse these definitions to set
Lua LPeg lexer styles manually if you chose not to have them set
automatically using the [`SCI_GETDIRECTFUNCTION()`](#SCI_GETDIRECTFUNCTION)
and [`SCI_SETDOCPOINTER()`](#SCI_SETDOCPOINTER) Scintillua API calls.

[SciTE documentation]: http://scintilla.org/SciTEDoc.html

Fields:

* `styleNum`: (`int`) For the range `-STYLE_MAX <= styleNum < 0`, uses the
  Scintilla style number `-styleNum - 1` for returning SciTE-formatted style
  definitions. (Style `0` would be `-1`, style `1` would be `-2`, and so on.)
* `style`: (`char *`) If `NULL`, returns the length that should be
  allocated to store the associated string. Otherwise fills the buffer with
  the string.


- - -

<a id="lexer"></a>
## The `lexer` Module

- - -

Lexes Scintilla documents and source code with Lua and LPeg.


<a id="lexer.Writing.Lua.Lexers"></a>

### Writing Lua Lexers

Lexers highlight the syntax of source code. Scintilla (the editing component
behind [Textadept][] and [SciTE][]) traditionally uses static, compiled C++
lexers which are notoriously difficult to create and/or extend. On the other
hand, Lua makes it easy to to rapidly create new lexers, extend existing
ones, and embed lexers within one another. Lua lexers tend to be more
readable than C++ lexers too.

Lexers are Parsing Expression Grammars, or PEGs, composed with the Lua
[LPeg library][]. The following table comes from the LPeg documentation and
summarizes all you need to know about constructing basic LPeg patterns. This
module provides convenience functions for creating and working with other
more advanced patterns and concepts.

Operator             | Description
---------------------|------------
`lpeg.P(string)`     | Matches `string` literally.
`lpeg.P(`_`n`_`)`    | Matches exactly _`n`_ number of characters.
`lpeg.S(string)`     | Matches any character in set `string`.
`lpeg.R("`_`xy`_`")` | Matches any character between range `x` and `y`.
`patt^`_`n`_         | Matches at least _`n`_ repetitions of `patt`.
`patt^-`_`n`_        | Matches at most _`n`_ repetitions of `patt`.
`patt1 * patt2`      | Matches `patt1` followed by `patt2`.
`patt1 + patt2`      | Matches `patt1` or `patt2` (ordered choice).
`patt1 - patt2`      | Matches `patt1` if `patt2` does not also match.
`-patt`              | Equivalent to `("" - patt)`.
`#patt`              | Matches `patt` but consumes no input.

The first part of this document deals with rapidly constructing a simple
lexer. The next part deals with more advanced techniques, such as custom
coloring and embedding lexers within one another. Following that is a
discussion about code folding, or being able to tell Scintilla which code
blocks are "foldable" (temporarily hideable from view). After that are
instructions on how to use Lua lexers with the aforementioned Textadept and
SciTE editors. Finally there are comments on lexer performance and
limitations.

[LPeg library]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[Textadept]: http://foicica.com/textadept
[SciTE]: http://scintilla.org/SciTE.html


<a id="lexer.Lexer.Basics"></a>

#### Lexer Basics

The *lexers/* directory contains all lexers, including your new one. Before
attempting to write one from scratch though, first determine if your
programming language is similar to any of the 100+ languages supported. If
so, you may be able to copy and modify that lexer, saving some time and
effort. The filename of your lexer should be the name of your programming
language in lower case followed by a *.lua* extension. For example, a new Lua
lexer has the name *lua.lua*.

Note: Try to refrain from using one-character language names like "c", "d",
or "r". For example, Scintillua uses "ansi_c", "dmd", and "rstats",
respectively.


<a id="lexer.New.Lexer.Template"></a>

##### New Lexer Template

There is a *lexers/template.txt* file that contains a simple template for a
new lexer. Feel free to use it, replacing the '?'s with the name of your
lexer. Consider this snippet from the template:

    -- ? LPeg lexer.

    local lexer = require('lexer')
    local token, word_match = lexer.token, lexer.word_match
    local P, S = lpeg.P, lpeg.S

    local lex = lexer.new('?')

    -- Whitespace.
    local ws = token(lexer.WHITESPACE, lexer.space^1)
    lex:add_rule('whitespace', ws)

    [...]

    return lex

The first 3 lines of code simply define often used convenience variables. The
fourth and last lines [define](#lexer.new) and return the lexer object
Scintilla uses; they are very important and must be part of every lexer. The
fifth line defines something called a "token", an essential building block of
lexers. You will learn about tokens shortly. The sixth line defines a lexer
grammar rule, which you will learn about later, as well as token styles. (Be
aware that it is common practice to combine these two lines for short rules.)
Note, however, the `local` prefix in front of variables, which is needed
so-as not to affect Lua's global environment. All in all, this is a minimal,
working lexer that you can build on.


<a id="lexer.Tokens"></a>

##### Tokens

Take a moment to think about your programming language's structure. What kind
of key elements does it have? In the template shown earlier, one predefined
element all languages have is whitespace. Your language probably also has
elements like comments, strings, and keywords. Lexers refer to these elements
as "tokens". Tokens are the fundamental "building blocks" of lexers. Lexers
break down source code into tokens for coloring, which results in the syntax
highlighting familiar to you. It is up to you how specific your lexer is when
it comes to tokens. Perhaps only distinguishing between keywords and
identifiers is necessary, or maybe recognizing constants and built-in
functions, methods, or libraries is desirable. The Lua lexer, for example,
defines 11 tokens: whitespace, keywords, built-in functions, constants,
built-in libraries, identifiers, strings, comments, numbers, labels, and
operators. Even though constants, built-in functions, and built-in libraries
are subsets of identifiers, Lua programmers find it helpful for the lexer to
distinguish between them all. It is perfectly acceptable to just recognize
keywords and identifiers.

In a lexer, tokens consist of a token name and an LPeg pattern that matches a
sequence of characters recognized as an instance of that token. Create tokens
using the [`lexer.token()`](#lexer.token) function. Let us examine the "whitespace" token
defined in the template shown earlier:

    local ws = token(lexer.WHITESPACE, lexer.space^1)

At first glance, the first argument does not appear to be a string name and
the second argument does not appear to be an LPeg pattern. Perhaps you
expected something like:

    local ws = token('whitespace', S('\t\v\f\n\r ')^1)

The `lexer` module actually provides a convenient list of common token names
and common LPeg patterns for you to use. Token names include
[`lexer.DEFAULT`](#lexer.DEFAULT), [`lexer.WHITESPACE`](#lexer.WHITESPACE), [`lexer.COMMENT`](#lexer.COMMENT),
[`lexer.STRING`](#lexer.STRING), [`lexer.NUMBER`](#lexer.NUMBER), [`lexer.KEYWORD`](#lexer.KEYWORD),
[`lexer.IDENTIFIER`](#lexer.IDENTIFIER), [`lexer.OPERATOR`](#lexer.OPERATOR), [`lexer.ERROR`](#lexer.ERROR),
[`lexer.PREPROCESSOR`](#lexer.PREPROCESSOR), [`lexer.CONSTANT`](#lexer.CONSTANT), [`lexer.VARIABLE`](#lexer.VARIABLE),
[`lexer.FUNCTION`](#lexer.FUNCTION), [`lexer.CLASS`](#lexer.CLASS), [`lexer.TYPE`](#lexer.TYPE), [`lexer.LABEL`](#lexer.LABEL),
[`lexer.REGEX`](#lexer.REGEX), and [`lexer.EMBEDDED`](#lexer.EMBEDDED). Patterns include
[`lexer.any`](#lexer.any), [`lexer.alpha`](#lexer.alpha), [`lexer.digit`](#lexer.digit), [`lexer.alnum`](#lexer.alnum),
[`lexer.lower`](#lexer.lower), [`lexer.upper`](#lexer.upper), [`lexer.xdigit`](#lexer.xdigit), [`lexer.graph`](#lexer.graph),
[`lexer.print`](#lexer.print), [`lexer.punct`](#lexer.punct), [`lexer.space`](#lexer.space), [`lexer.newline`](#lexer.newline),
[`lexer.nonnewline`](#lexer.nonnewline), [`lexer.dec_num`](#lexer.dec_num), [`lexer.hex_num`](#lexer.hex_num),
[`lexer.oct_num`](#lexer.oct_num), [`lexer.integer`](#lexer.integer), [`lexer.float`](#lexer.float),
[`lexer.number`](#lexer.number), and [`lexer.word`](#lexer.word). You may use your own token names if
none of the above fit your language, but an advantage to using predefined
token names is that your lexer's tokens will inherit the universal syntax
highlighting color theme used by your text editor.


<a id="lexer.Example.Tokens"></a>

###### Example Tokens

So, how might you define other tokens like keywords, comments, and strings?
Here are some examples.

**Keywords**

Instead of matching _n_ keywords with _n_ `P('keyword_`_`n`_`')` ordered
choices, use another convenience function: [`lexer.word_match()`](#lexer.word_match). It is
much easier and more efficient to write word matches like:

    local keyword = token(lexer.KEYWORD, lexer.word_match[[
      keyword_1 keyword_2 ... keyword_n
    ]])

    local case_insensitive_keyword = token(lexer.KEYWORD, lexer.word_match([[
      KEYWORD_1 keyword_2 ... KEYword_n
    ]], true))

    local hyphened_keyword = token(lexer.KEYWORD, lexer.word_match[[
      keyword-1 keyword-2 ... keyword-n
    ]])

In order to more easily separate or categorize keyword sets, you can use Lua
line comments within keyword strings. Such comments will be ignored. For
example:

    local keyword = token(lexer.KEYWORD, lexer.word_match[[
      -- Version 1 keywords.
      keyword_11, keyword_12 ... keyword_1n
      -- Version 2 keywords.
      keyword_21, keyword_22 ... keyword_2n
      ...
      -- Version N keywords.
      keyword_m1, keyword_m2 ... keyword_mn
    ]])

**Comments**

Line-style comments with a prefix character(s) are easy to express with LPeg:

    local shell_comment = token(lexer.COMMENT, lexer.to_eol('#'))
    local c_line_comment = token(lexer.COMMENT, lexer.to_eol('//', true))

The comments above start with a '#' or "//" and go to the end of the line.
The second comment recognizes the next line also as a comment if the current
line ends with a '\' escape character.

C-style "block" comments with a start and end delimiter are also easy to
express:

    local c_comment = token(lexer.COMMENT, lexer.range('/*', '*/'))

This comment starts with a "/\*" sequence and contains anything up to and
including an ending "\*/" sequence. The ending "\*/" is optional so the lexer
can recognize unfinished comments as comments and highlight them properly.

**Strings**

Most programming languages allow escape sequences in strings such that a
sequence like "\\&quot;" in a double-quoted string indicates that the
'&quot;' is not the end of the string. [`lexer.range()`](#lexer.range) handles escapes
inherently.

    local dq_str = lexer.range('"')
    local sq_str = lexer.range("'")
    local string = token(lexer.STRING, dq_str + sq_str)

In this case, the lexer treats '\' as an escape character in a string
sequence.

**Numbers**

Most programming languages have the same format for integer and float tokens,
so it might be as simple as using a predefined LPeg pattern:

    local number = token(lexer.NUMBER, lexer.number)

However, some languages allow postfix characters on integers.

    local integer = P('-')^-1 * (lexer.dec_num * S('lL')^-1)
    local number = token(lexer.NUMBER, lexer.float + lexer.hex_num + integer)

Your language may need other tweaks, but it is up to you how fine-grained you
want your highlighting to be. After all, you are not writing a compiler or
interpreter!


<a id="lexer.Rules"></a>

##### Rules

Programming languages have grammars, which specify valid token structure. For
example, comments usually cannot appear within a string. Grammars consist of
rules, which are simply combinations of tokens. Recall from the lexer
template the [`lexer.add_rule()`](#lexer.add_rule) call, which adds a rule to the lexer's
grammar:

    lex:add_rule('whitespace', ws)

Each rule has an associated name, but rule names are completely arbitrary and
serve only to identify and distinguish between different rules. Rule order is
important: if text does not match the first rule added to the grammar, the
lexer tries to match the second rule added, and so on. Right now this lexer
simply matches whitespace tokens under a rule named "whitespace".

To illustrate the importance of rule order, here is an example of a
simplified Lua lexer:

    lex:add_rule('whitespace', token(lexer.WHITESPACE, ...))
    lex:add_rule('keyword', token(lexer.KEYWORD, ...))
    lex:add_rule('identifier', token(lexer.IDENTIFIER, ...))
    lex:add_rule('string', token(lexer.STRING, ...))
    lex:add_rule('comment', token(lexer.COMMENT, ...))
    lex:add_rule('number', token(lexer.NUMBER, ...))
    lex:add_rule('label', token(lexer.LABEL, ...))
    lex:add_rule('operator', token(lexer.OPERATOR, ...))

Note how identifiers come after keywords. In Lua, as with most programming
languages, the characters allowed in keywords and identifiers are in the same
set (alphanumerics plus underscores). If the lexer added the "identifier"
rule before the "keyword" rule, all keywords would match identifiers and thus
incorrectly highlight as identifiers instead of keywords. The same idea
applies to function, constant, etc. tokens that you may want to distinguish
between: their rules should come before identifiers.

So what about text that does not match any rules? For example in Lua, the '!'
character is meaningless outside a string or comment. Normally the lexer
skips over such text. If instead you want to highlight these "syntax errors",
add an additional end rule:

    lex:add_rule('whitespace', ws)
    ...
    lex:add_rule('error', token(lexer.ERROR, lexer.any))

This identifies and highlights any character not matched by an existing
rule as a `lexer.ERROR` token.

Even though the rules defined in the examples above contain a single token,
rules may consist of multiple tokens. For example, a rule for an HTML tag
could consist of a tag token followed by an arbitrary number of attribute
tokens, allowing the lexer to highlight all tokens separately. That rule
might look something like this:

    lex:add_rule('tag', tag_start * (ws * attributes)^0 * tag_end^-1)

Note however that lexers with complex rules like these are more prone to lose
track of their state, especially if they span multiple lines.


<a id="lexer.Summary"></a>

##### Summary

Lexers primarily consist of tokens and grammar rules. At your disposal are a
number of convenience patterns and functions for rapidly creating a lexer. If
you choose to use predefined token names for your tokens, you do not have to
define how the lexer highlights them. The tokens will inherit the default
syntax highlighting color theme your editor uses.


<a id="lexer.Advanced.Techniques"></a>

#### Advanced Techniques


<a id="lexer.Styles.and.Styling"></a>

##### Styles and Styling

The most basic form of syntax highlighting is assigning different colors to
different tokens. Instead of highlighting with just colors, Scintilla allows
for more rich highlighting, or "styling", with different fonts, font sizes,
font attributes, and foreground and background colors, just to name a few.
The unit of this rich highlighting is called a "style". Styles are simply Lua
tables of properties. By default, lexers associate predefined token names
like `lexer.WHITESPACE`, `lexer.COMMENT`, `lexer.STRING`, etc. with
particular styles as part of a universal color theme. These predefined styles
are contained in [`lexer.styles`](#lexer.styles), and you may define your own styles. See
that table's documentation for more information. As with token names,
LPeg patterns, and styles, there is a set of predefined color names, but they
vary depending on the current color theme in use. Therefore, it is generally
not a good idea to manually define colors within styles in your lexer since
they might not fit into a user's chosen color theme. Try to refrain from even
using predefined colors in a style because that color may be theme-specific.
Instead, the best practice is to either use predefined styles or derive new
color-agnostic styles from predefined ones. For example, Lua "longstring"
tokens use the existing `lexer.styles.string` style instead of defining a new
one.


<a id="lexer.Example.Styles"></a>

###### Example Styles

Defining styles is pretty straightforward. An empty style that inherits the
default theme settings is simply an empty table:

    local style_nothing = {}

A similar style but with a bold font face looks like this:

    local style_bold = {bold = true}

You can derive new styles from predefined ones without having to rewrite
them. This operation leaves the old style unchanged. For example, if you had
a "static variable" token whose style you wanted to base off of
`lexer.styles.variable`, it would probably look like:

    local style_static_var = lexer.styles.variable .. {italics = true}

The color theme files in the *lexers/themes/* folder give more examples of
style definitions.


<a id="lexer.Token.Styles"></a>

##### Token Styles

Lexers use the [`lexer.add_style()`](#lexer.add_style) function to assign styles to
particular tokens. Recall the token definition and from the lexer template:

    local ws = token(lexer.WHITESPACE, lexer.space^1)
    lex:add_rule('whitespace', ws)

Why is a style not assigned to the `lexer.WHITESPACE` token? As mentioned
earlier, lexers automatically associate tokens that use predefined token
names with a particular style. Only tokens with custom token names need
manual style associations. As an example, consider a custom whitespace token:

    local ws = token('custom_whitespace', lexer.space^1)

Assigning a style to this token looks like:

    lex:add_style('custom_whitespace', lexer.styles.whitespace)

Do not confuse token names with rule names. They are completely different
entities. In the example above, the lexer associates the "custom_whitespace"
token with the existing style for `lexer.WHITESPACE` tokens. If instead you
prefer to color the background of whitespace a shade of grey, it might look
like:

    lex:add_style('custom_whitespace',
                  lexer.styles.whitespace .. {back = lexer.colors.grey})

Remember to refrain from assigning specific colors in styles, but in this
case, all user color themes probably define `colors.grey`.


<a id="lexer.Line.Lexers"></a>

##### Line Lexers

By default, lexers match the arbitrary chunks of text passed to them by
Scintilla. These chunks may be a full document, only the visible part of a
document, or even just portions of lines. Some lexers need to match whole
lines. For example, a lexer for the output of a file "diff" needs to know if
the line started with a '+' or '-' and then style the entire line
accordingly. To indicate that your lexer matches by line, create the lexer
with an extra parameter:

    local lex = lexer.new('?', {lex_by_line = true})

Now the input text for the lexer is a single line at a time. Keep in mind
that line lexers do not have the ability to look ahead at subsequent lines.


<a id="lexer.Embedded.Lexers"></a>

##### Embedded Lexers

Lexers embed within one another very easily, requiring minimal effort. In the
following sections, the lexer being embedded is called the "child" lexer and
the lexer a child is being embedded in is called the "parent". For example,
consider an HTML lexer and a CSS lexer. Either lexer stands alone for styling
their respective HTML and CSS files. However, CSS can be embedded inside
HTML. In this specific case, the CSS lexer is the "child" lexer with the HTML
lexer being the "parent". Now consider an HTML lexer and a PHP lexer. This
sounds a lot like the case with CSS, but there is a subtle difference: PHP
_embeds itself into_ HTML while CSS is _embedded in_ HTML. This fundamental
difference results in two types of embedded lexers: a parent lexer that
embeds other child lexers in it (like HTML embedding CSS), and a child lexer
that embeds itself into a parent lexer (like PHP embedding itself in HTML).


<a id="lexer.Parent.Lexer"></a>

###### Parent Lexer

Before embedding a child lexer into a parent lexer, the parent lexer needs to
load the child lexer. This is done with the [`lexer.load()`](#lexer.load) function. For
example, loading the CSS lexer within the HTML lexer looks like:

    local css = lexer.load('css')

The next part of the embedding process is telling the parent lexer when to
switch over to the child lexer and when to switch back. The lexer refers to
these indications as the "start rule" and "end rule", respectively, and are
just LPeg patterns. Continuing with the HTML/CSS example, the transition from
HTML to CSS is when the lexer encounters a "style" tag with a "type"
attribute whose value is "text/css":

    local css_tag = P('<style') * P(function(input, index)
      if input:find('^[^>]+type="text/css"', index) then
        return index
      end
    end)

This pattern looks for the beginning of a "style" tag and searches its
attribute list for the text "`type="text/css"`". (In this simplified example,
the Lua pattern does not consider whitespace between the '=' nor does it
consider that using single quotes is valid.) If there is a match, the
functional pattern returns a value instead of `nil`. In this case, the value
returned does not matter because we ultimately want to style the "style" tag
as an HTML tag, so the actual start rule looks like this:

    local css_start_rule = #css_tag * tag

Now that the parent knows when to switch to the child, it needs to know when
to switch back. In the case of HTML/CSS, the switch back occurs when the
lexer encounters an ending "style" tag, though the lexer should still style
the tag as an HTML tag:

    local css_end_rule = #P('</style>') * tag

Once the parent loads the child lexer and defines the child's start and end
rules, it embeds the child with the [`lexer.embed()`](#lexer.embed) function:

    lex:embed(css, css_start_rule, css_end_rule)


<a id="lexer.Child.Lexer"></a>

###### Child Lexer

The process for instructing a child lexer to embed itself into a parent is
very similar to embedding a child into a parent: first, load the parent lexer
into the child lexer with the [`lexer.load()`](#lexer.load) function and then create
start and end rules for the child lexer. However, in this case, call
[`lexer.embed()`](#lexer.embed) with switched arguments. For example, in the PHP lexer:

    local html = lexer.load('html')
    local php_start_rule = token('php_tag', '<?php ')
    local php_end_rule = token('php_tag', '?>')
    lex:add_style('php_tag', lexer.styles.embedded)
    html:embed(lex, php_start_rule, php_end_rule)


<a id="lexer.Lexers.with.Complex.State"></a>

##### Lexers with Complex State

A vast majority of lexers are not stateful and can operate on any chunk of
text in a document. However, there may be rare cases where a lexer does need
to keep track of some sort of persistent state. Rather than using `lpeg.P`
function patterns that set state variables, it is recommended to make use of
Scintilla's built-in, per-line state integers via [`lexer.line_state`](#lexer.line_state). It
was designed to accommodate up to 32 bit flags for tracking state.
[`lexer.line_from_position()`](#lexer.line_from_position) will return the line for any position given
to an `lpeg.P` function pattern. (Any positions derived from that position
argument will also work.)

Writing stateful lexers is beyond the scope of this document.


<a id="lexer.Code.Folding"></a>

#### Code Folding

When reading source code, it is occasionally helpful to temporarily hide
blocks of code like functions, classes, comments, etc. This is the concept of
"folding". In the Textadept and SciTE editors for example, little indicators
in the editor margins appear next to code that can be folded at places called
"fold points". When the user clicks an indicator, the editor hides the code
associated with the indicator until the user clicks the indicator again. The
lexer specifies these fold points and what code exactly to fold.

The fold points for most languages occur on keywords or character sequences.
Examples of fold keywords are "if" and "end" in Lua and examples of fold
character sequences are '{', '}', "/\*", and "\*/" in C for code block and
comment delimiters, respectively. However, these fold points cannot occur
just anywhere. For example, lexers should not recognize fold keywords that
appear within strings or comments. The [`lexer.add_fold_point()`](#lexer.add_fold_point) function
allows you to conveniently define fold points with such granularity. For
example, consider C:

    lex:add_fold_point(lexer.OPERATOR, '{', '}')
    lex:add_fold_point(lexer.COMMENT, '/*', '*/')

The first assignment states that any '{' or '}' that the lexer recognized as
an `lexer.OPERATOR` token is a fold point. Likewise, the second assignment
states that any "/\*" or "\*/" that the lexer recognizes as part of a
`lexer.COMMENT` token is a fold point. The lexer does not consider any
occurrences of these characters outside their defined tokens (such as in a
string) as fold points. How do you specify fold keywords? Here is an example
for Lua:

    lex:add_fold_point(lexer.KEYWORD, 'if', 'end')
    lex:add_fold_point(lexer.KEYWORD, 'do', 'end')
    lex:add_fold_point(lexer.KEYWORD, 'function', 'end')
    lex:add_fold_point(lexer.KEYWORD, 'repeat', 'until')

If your lexer has case-insensitive keywords as fold points, simply add a
`case_insensitive_fold_points = true` option to [`lexer.new()`](#lexer.new), and
specify keywords in lower case.

If your lexer needs to do some additional processing in order to determine if
a token is a fold point, pass a function that returns an integer to
`lex:add_fold_point()`. Returning `1` indicates the token is a beginning fold
point and returning `-1` indicates the token is an ending fold point.
Returning `0` indicates the token is not a fold point. For example:

    local function fold_strange_token(text, pos, line, s, symbol)
      if ... then
        return 1 -- beginning fold point
      elseif ... then
        return -1 -- ending fold point
      end
      return 0
    end

    lex:add_fold_point('strange_token', '|', fold_strange_token)

Any time the lexer encounters a '|' that is a "strange_token", it calls the
`fold_strange_token` function to determine if '|' is a fold point. The lexer
calls these functions with the following arguments: the text to identify fold
points in, the beginning position of the current line in the text to fold,
the current line's text, the position in the current line the fold point text
starts at, and the fold point text itself.


<a id="lexer.Fold.by.Indentation"></a>

##### Fold by Indentation

Some languages have significant whitespace and/or no delimiters that indicate
fold points. If your lexer falls into this category and you would like to
mark fold points based on changes in indentation, create the lexer with a
`fold_by_indentation = true` option:

    local lex = lexer.new('?', {fold_by_indentation = true})


<a id="lexer.Using.Lexers"></a>

#### Using Lexers


<a id="lexer.Textadept"></a>

##### Textadept

Put your lexer in your *~/.textadept/lexers/* directory so you do not
overwrite it when upgrading Textadept. Also, lexers in this directory
override default lexers. Thus, Textadept loads a user *lua* lexer instead of
the default *lua* lexer. This is convenient for tweaking a default lexer to
your liking. Then add a [file type][] for your lexer if necessary.

[file type]: textadept.file_types.html


<a id="lexer.SciTE"></a>

##### SciTE

Create a *.properties* file for your lexer and `import` it in either your
*SciTEUser.properties* or *SciTEGlobal.properties*. The contents of the
*.properties* file should contain:

    file.patterns.[lexer_name]=[file_patterns]
    lexer.$(file.patterns.[lexer_name])=[lexer_name]

where `[lexer_name]` is the name of your lexer (minus the *.lua* extension)
and `[file_patterns]` is a set of file extensions to use your lexer for.

Please note that Lua lexers ignore any styling information in *.properties*
files. Your theme file in the *lexers/themes/* directory contains styling
information.


<a id="lexer.Migrating.Legacy.Lexers"></a>

#### Migrating Legacy Lexers

Legacy lexers are of the form:

    local l = require('lexer')
    local token, word_match = l.token, l.word_match
    local P, R, S = lpeg.P, lpeg.R, lpeg.S

    local M = {_NAME = '?'}

    [... token and pattern definitions ...]

    M._rules = {
      {'rule', pattern},
      [...]
    }

    M._tokenstyles = {
      'token' = 'style',
      [...]
    }

    M._foldsymbols = {
      _patterns = {...},
      ['token'] = {['start'] = 1, ['end'] = -1},
      [...]
    }

    return M

While Scintillua will handle such legacy lexers just fine without any
changes, it is recommended that you migrate yours. The migration process is
fairly straightforward:

1. Replace all instances of `l` with `lexer`, as it's better practice and
   results in less confusion.
2. Replace `local M = {_NAME = '?'}` with `local lex = lexer.new('?')`, where
   `?` is the name of your legacy lexer. At the end of the lexer, change
   `return M` to `return lex`.
3. Instead of defining rules towards the end of your lexer, define your rules
   as you define your tokens and patterns using
   [`lex:add_rule()`](#lexer.add_rule).
4. Similarly, any custom token names should have their styles immediately
   defined using [`lex:add_style()`](#lexer.add_style).
5. Convert any table arguments passed to [`lexer.word_match()`](#lexer.word_match) to a
   space-separated string of words.
6. Replace any calls to `lexer.embed(M, child, ...)` and
   `lexer.embed(parent, M, ...)` with
   [`lex:embed`](#lexer.embed)`(child, ...)` and `parent:embed(lex, ...)`,
   respectively.
7. Define fold points with simple calls to
   [`lex:add_fold_point()`](#lexer.add_fold_point). No need to mess with Lua
   patterns anymore.
8. Any legacy lexer options such as `M._FOLDBYINDENTATION`, `M._LEXBYLINE`,
   `M._lexer`, etc. should be added as table options to [`lexer.new()`](#lexer.new).
9. Any external lexer rule fetching and/or modifications via `lexer._RULES`
   should be changed to use [`lexer.get_rule()`](#lexer.get_rule) and
   [`lexer.modify_rule()`](#lexer.modify_rule).

As an example, consider the following sample legacy lexer:

    local l = require('lexer')
    local token, word_match = l.token, l.word_match
    local P, R, S = lpeg.P, lpeg.R, lpeg.S

    local M = {_NAME = 'legacy'}

    local ws = token(l.WHITESPACE, l.space^1)
    local comment = token(l.COMMENT, '#' * l.nonnewline^0)
    local string = token(l.STRING, l.delimited_range('"'))
    local number = token(l.NUMBER, l.float + l.integer)
    local keyword = token(l.KEYWORD, word_match{'foo', 'bar', 'baz'})
    local custom = token('custom', P('quux'))
    local identifier = token(l.IDENTIFIER, l.word)
    local operator = token(l.OPERATOR, S('+-*/%^=<>,.()[]{}'))

    M._rules = {
      {'whitespace', ws},
      {'keyword', keyword},
      {'custom', custom},
      {'identifier', identifier},
      {'string', string},
      {'comment', comment},
      {'number', number},
      {'operator', operator}
    }

    M._tokenstyles = {
      'custom' = l.STYLE_KEYWORD .. ',bold'
    }

    M._foldsymbols = {
      _patterns = {'[{}]'},
      [l.OPERATOR] = {['{'] = 1, ['}'] = -1}
    }

    return M

Following the migration steps would yield:

    local lexer = require('lexer')
    local token, word_match = lexer.token, lexer.word_match
    local P, S = lpeg.P, lpeg.S

    local lex = lexer.new('legacy')

    lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))
    lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[foo bar baz]]))
    lex:add_rule('custom', token('custom', P('quux')))
    lex:add_style('custom', lexer.styles.keyword .. {bold = true})
    lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))
    lex:add_rule('string', token(lexer.STRING, lexer.range('"')))
    lex:add_rule('comment', token(lexer.COMMENT, lexer.to_eol('#')))
    lex:add_rule('number', token(lexer.NUMBER, lexer.number))
    lex:add_rule('operator', token(lexer.OPERATOR, S('+-*/%^=<>,.()[]{}')))

    lex:add_fold_point(lexer.OPERATOR, '{', '}')

    return lex


<a id="lexer.Considerations"></a>

#### Considerations


<a id="lexer.Performance"></a>

##### Performance

There might be some slight overhead when initializing a lexer, but loading a
file from disk into Scintilla is usually more expensive. On modern computer
systems, I see no difference in speed between Lua lexers and Scintilla's C++
ones. Optimize lexers for speed by re-arranging `lexer.add_rule()` calls so
that the most common rules match first. Do keep in mind that order matters
for similar rules.

In some cases, folding may be far more expensive than lexing, particularly
in lexers with a lot of potential fold points. If your lexer is exhibiting
signs of slowness, try disabling folding in your text editor first. If that
speeds things up, you can try reducing the number of fold points you added,
overriding `lexer.fold()` with your own implementation, or simply eliminating
folding support from your lexer.


<a id="lexer.Limitations"></a>

##### Limitations

Embedded preprocessor languages like PHP cannot completely embed in their
parent languages in that the parent's tokens do not support start and end
rules. This mostly goes unnoticed, but code like

    <div id="<?php echo $id; ?>">

will not style correctly.


<a id="lexer.Troubleshooting"></a>

##### Troubleshooting

Errors in lexers can be tricky to debug. Lexers print Lua errors to
`io.stderr` and `_G.print()` statements to `io.stdout`. Running your editor
from a terminal is the easiest way to see errors as they occur.


<a id="lexer.Risks"></a>

##### Risks

Poorly written lexers have the ability to crash Scintilla (and thus its
containing application), so unsaved data might be lost. However, I have only
observed these crashes in early lexer development, when syntax errors or
pattern errors are present. Once the lexer actually starts styling text
(either correctly or incorrectly, it does not matter), I have not observed
any crashes.


<a id="lexer.Acknowledgements"></a>

##### Acknowledgements

Thanks to Peter Odding for his [lexer post][] on the Lua mailing list
that provided inspiration, and thanks to Roberto Ierusalimschy for LPeg.

[lexer post]: http://lua-users.org/lists/lua-l/2007-04/msg00116.html

### Fields defined by `lexer`

<a id="lexer.CLASS"></a>
#### `lexer.CLASS` (string)

The token name for class tokens.

<a id="lexer.COMMENT"></a>
#### `lexer.COMMENT` (string)

The token name for comment tokens.

<a id="lexer.CONSTANT"></a>
#### `lexer.CONSTANT` (string)

The token name for constant tokens.

<a id="lexer.DEFAULT"></a>
#### `lexer.DEFAULT` (string)

The token name for default tokens.

<a id="lexer.ERROR"></a>
#### `lexer.ERROR` (string)

The token name for error tokens.

<a id="lexer.FOLD_BASE"></a>
#### `lexer.FOLD_BASE` (number)

The initial (root) fold level.

<a id="lexer.FOLD_BLANK"></a>
#### `lexer.FOLD_BLANK` (number)

Flag indicating that the line is blank.

<a id="lexer.FOLD_HEADER"></a>
#### `lexer.FOLD_HEADER` (number)

Flag indicating the line is fold point.

<a id="lexer.FUNCTION"></a>
#### `lexer.FUNCTION` (string)

The token name for function tokens.

<a id="lexer.IDENTIFIER"></a>
#### `lexer.IDENTIFIER` (string)

The token name for identifier tokens.

<a id="lexer.KEYWORD"></a>
#### `lexer.KEYWORD` (string)

The token name for keyword tokens.

<a id="lexer.LABEL"></a>
#### `lexer.LABEL` (string)

The token name for label tokens.

<a id="lexer.NUMBER"></a>
#### `lexer.NUMBER` (string)

The token name for number tokens.

<a id="lexer.OPERATOR"></a>
#### `lexer.OPERATOR` (string)

The token name for operator tokens.

<a id="lexer.PREPROCESSOR"></a>
#### `lexer.PREPROCESSOR` (string)

The token name for preprocessor tokens.

<a id="lexer.REGEX"></a>
#### `lexer.REGEX` (string)

The token name for regex tokens.

<a id="lexer.STRING"></a>
#### `lexer.STRING` (string)

The token name for string tokens.

<a id="lexer.TYPE"></a>
#### `lexer.TYPE` (string)

The token name for type tokens.

<a id="lexer.VARIABLE"></a>
#### `lexer.VARIABLE` (string)

The token name for variable tokens.

<a id="lexer.WHITESPACE"></a>
#### `lexer.WHITESPACE` (string)

The token name for whitespace tokens.

<a id="lexer.alnum"></a>
#### `lexer.alnum` (pattern)

A pattern that matches any alphanumeric character ('A'-'Z', 'a'-'z',
    '0'-'9').

<a id="lexer.alpha"></a>
#### `lexer.alpha` (pattern)

A pattern that matches any alphabetic character ('A'-'Z', 'a'-'z').

<a id="lexer.any"></a>
#### `lexer.any` (pattern)

A pattern that matches any single character.

<a id="lexer.ascii"></a>
#### `lexer.ascii` (pattern)

A pattern that matches any ASCII character (codes 0 to 127).

<a id="lexer.cntrl"></a>
#### `lexer.cntrl` (pattern)

A pattern that matches any control character (ASCII codes 0 to 31).

<a id="lexer.dec_num"></a>
#### `lexer.dec_num` (pattern)

A pattern that matches a decimal number.

<a id="lexer.digit"></a>
#### `lexer.digit` (pattern)

A pattern that matches any digit ('0'-'9').

<a id="lexer.extend"></a>
#### `lexer.extend` (pattern)

A pattern that matches any ASCII extended character (codes 0 to 255).

<a id="lexer.float"></a>
#### `lexer.float` (pattern)

A pattern that matches a floating point number.

<a id="lexer.fold_by_indentation"></a>
#### `lexer.fold_by_indentation` (boolean)

Whether or not to fold based on indentation level if a lexer does not have
  a folder.
  Some lexers automatically enable this option. It is disabled by default.
  This is an alias for `lexer.property['fold.by.indentation'] = '1|0'`.

<a id="lexer.fold_compact"></a>
#### `lexer.fold_compact` (boolean)

Whether or not blank lines after an ending fold point are included in that
  fold.
  This option is disabled by default.
  This is an alias for `lexer.property['fold.compact'] = '1|0'`.

<a id="lexer.fold_level"></a>
#### `lexer.fold_level` (table, Read-only)

Table of fold level bit-masks for line numbers starting from 1.
  Fold level masks are composed of an integer level combined with any of the
  following bits:

  * `lexer.FOLD_BASE`
    The initial fold level.
  * `lexer.FOLD_BLANK`
    The line is blank.
  * `lexer.FOLD_HEADER`
    The line is a header, or fold point.

<a id="lexer.fold_line_groups"></a>
#### `lexer.fold_line_groups` (boolean)

Whether or not to fold multiple, consecutive line groups (such as line
  comments and import statements) and only show the top line.
  This option is disabled by default.
  This is an alias for `lexer.property['fold.line.groups'] = '1|0'`.

<a id="lexer.fold_on_zero_sum_lines"></a>
#### `lexer.fold_on_zero_sum_lines` (boolean)

Whether or not to mark as a fold point lines that contain both an ending
  and starting fold point. For example, `} else {` would be marked as a fold
  point.
  This option is disabled by default.
  This is an alias for `lexer.property['fold.on.zero.sum.lines'] = '1|0'`.

<a id="lexer.folding"></a>
#### `lexer.folding` (boolean)

Whether or not folding is enabled for the lexers that support it.
  This option is disabled by default.
  This is an alias for `lexer.property['fold'] = '1|0'`.

<a id="lexer.graph"></a>
#### `lexer.graph` (pattern)

A pattern that matches any graphical character ('!' to '~').

<a id="lexer.hex_num"></a>
#### `lexer.hex_num` (pattern)

A pattern that matches a hexadecimal number.

<a id="lexer.indent_amount"></a>
#### `lexer.indent_amount` (table, Read-only)

Table of indentation amounts in character columns, for line numbers
  starting from 1.

<a id="lexer.integer"></a>
#### `lexer.integer` (pattern)

A pattern that matches either a decimal, hexadecimal, or octal number.

<a id="lexer.line_state"></a>
#### `lexer.line_state` (table)

Table of integer line states for line numbers starting from 1.
  Line states can be used by lexers for keeping track of persistent states.

<a id="lexer.lower"></a>
#### `lexer.lower` (pattern)

A pattern that matches any lower case character ('a'-'z').

<a id="lexer.newline"></a>
#### `lexer.newline` (pattern)

A pattern that matches a sequence of end of line characters.

<a id="lexer.nonnewline"></a>
#### `lexer.nonnewline` (pattern)

A pattern that matches any single, non-newline character.

<a id="lexer.number"></a>
#### `lexer.number` (pattern)

A pattern that matches a typical number, either a floating point, decimal,
  hexadecimal, or octal number.

<a id="lexer.oct_num"></a>
#### `lexer.oct_num` (pattern)

A pattern that matches an octal number.

<a id="lexer.print"></a>
#### `lexer.print` (pattern)

A pattern that matches any printable character (' ' to '~').

<a id="lexer.property"></a>
#### `lexer.property` (table)

Map of key-value string pairs.

<a id="lexer.property_expanded"></a>
#### `lexer.property_expanded` (table, Read-only)

Map of key-value string pairs with `$()` and `%()` variable replacement
  performed in values.

<a id="lexer.property_int"></a>
#### `lexer.property_int` (table, Read-only)

Map of key-value pairs with values interpreted as numbers, or `0` if not
  found.

<a id="lexer.punct"></a>
#### `lexer.punct` (pattern)

A pattern that matches any punctuation character ('!' to '/', ':' to '@',
  '[' to ''', '{' to '~').

<a id="lexer.space"></a>
#### `lexer.space` (pattern)

A pattern that matches any whitespace character ('\t', '\v', '\f', '\n',
  '\r', space).

<a id="lexer.style_at"></a>
#### `lexer.style_at` (table, Read-only)

Table of style names at positions in the buffer starting from 1.

<a id="lexer.upper"></a>
#### `lexer.upper` (pattern)

A pattern that matches any upper case character ('A'-'Z').

<a id="lexer.word"></a>
#### `lexer.word` (pattern)

A pattern that matches a typical word. Words begin with a letter or
  underscore and consist of alphanumeric and underscore characters.

<a id="lexer.xdigit"></a>
#### `lexer.xdigit` (pattern)

A pattern that matches any hexadecimal digit ('0'-'9', 'A'-'F', 'a'-'f').


### Functions defined by `lexer`

<a id="lexer.add_fold_point"></a>
#### `lexer.add_fold_point`(lexer, token\_name, start\_symbol, end\_symbol)

Adds to lexer *lexer* a fold point whose beginning and end tokens are string
*token_name* tokens with string content *start_symbol* and *end_symbol*,
respectively.
In the event that *start_symbol* may or may not be a fold point depending on
context, and that additional processing is required, *end_symbol* may be a
function that ultimately returns `1` (indicating a beginning fold point),
`-1` (indicating an ending fold point), or `0` (indicating no fold point).
That function is passed the following arguments:

  * `text`: The text being processed for fold points.
  * `pos`: The position in *text* of the beginning of the line currently
    being processed.
  * `line`: The text of the line currently being processed.
  * `s`: The position of *start_symbol* in *line*.
  * `symbol`: *start_symbol* itself.

Fields:

* `lexer`: The lexer to add a fold point to.
* `token_name`: The token name of text that indicates a fold point.
* `start_symbol`: The text that indicates the beginning of a fold point.
* `end_symbol`: Either the text that indicates the end of a fold point, or
  a function that returns whether or not *start_symbol* is a beginning fold
  point (1), an ending fold point (-1), or not a fold point at all (0).

Usage:

* `lex:add_fold_point(lexer.OPERATOR, '{', '}')`
* `lex:add_fold_point(lexer.KEYWORD, 'if', 'end')`
* `lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('#'))`
* `lex:add_fold_point('custom', function(text, pos, line, s, symbol)
  ... end)`

<a id="lexer.add_rule"></a>
#### `lexer.add_rule`(lexer, id, rule)

Adds pattern *rule* identified by string *id* to the ordered list of rules
for lexer *lexer*.

Fields:

* `lexer`: The lexer to add the given rule to.
* `id`: The id associated with this rule. It does not have to be the same
  as the name passed to `token()`.
* `rule`: The LPeg pattern of the rule.

See also:

* [`lexer.modify_rule`](#lexer.modify_rule)

<a id="lexer.add_style"></a>
#### `lexer.add_style`(lexer, token\_name, style)

Associates string *token_name* in lexer *lexer* with style table *style*.
*style* may have the following fields:

* `font`: String font name.
* `size`: Integer font size.
* `bold`: Whether or not the font face is bold. The default value is `false`.
* `weight`: Integer weight or boldness of a font, between 1 and 999.
* `italics`: Whether or not the font face is italic. The default value is
  `false`.
* `underlined`: Whether or not the font face is underlined. The default value
  is `false`.
* `fore`: Font face foreground color in `0xBBGGRR` or `"#RRGGBB"` format.
* `back`: Font face background color in `0xBBGGRR` or `"#RRGGBB"` format.
* `eolfilled`: Whether or not the background color extends to the end of the
  line. The default value is `false`.
* `case`: Font case, `'u'` for upper, `'l'` for lower, and `'m'` for normal,
  mixed case. The default value is `'m'`.
* `visible`: Whether or not the text is visible. The default value is `true`.
* `changeable`: Whether the text is changeable instead of read-only. The
  default value is `true`.

Field values may also contain "$(property.name)" expansions for properties
defined in Scintilla, theme files, etc.

Fields:

* `lexer`: The lexer to add a style to.
* `token_name`: The name of the token to associated with the style.
* `style`: A style string for Scintilla.

Usage:

* `lex:add_style('longstring', lexer.styles.string)`
* `lex:add_style('deprecated_func', lexer.styles['function'] ..
  {italics = true}`
* `lex:add_style('visible_ws', lexer.styles.whitespace ..
  {back = lexer.colors.grey}`

<a id="lexer.embed"></a>
#### `lexer.embed`(lexer, child, start\_rule, end\_rule)

Embeds child lexer *child* in parent lexer *lexer* using patterns
*start_rule* and *end_rule*, which signal the beginning and end of the
embedded lexer, respectively.

Fields:

* `lexer`: The parent lexer.
* `child`: The child lexer.
* `start_rule`: The pattern that signals the beginning of the embedded
  lexer.
* `end_rule`: The pattern that signals the end of the embedded lexer.

Usage:

* `html:embed(css, css_start_rule, css_end_rule)`
* `html:embed(lex, php_start_rule, php_end_rule) -- from php lexer`

<a id="lexer.fold"></a>
#### `lexer.fold`(lexer, text, start\_pos, start\_line, start\_level)

Determines fold points in a chunk of text *text* using lexer *lexer*,
returning a table of fold levels associated with line numbers.
*text* starts at position *start_pos* on line number *start_line* with a
beginning fold level of *start_level* in the buffer.

Fields:

* `lexer`: The lexer to fold text with.
* `text`: The text in the buffer to fold.
* `start_pos`: The position in the buffer *text* starts at, counting from
  1.
* `start_line`: The line number *text* starts on, counting from 1.
* `start_level`: The fold level *text* starts on.

Return:

* table of fold levels associated with line numbers.

<a id="lexer.fold_consecutive_lines"></a>
#### `lexer.fold_consecutive_lines`(prefix)

Returns for `lexer.add_fold_point()` the parameters needed to fold
consecutive lines that start with string *prefix*.

Fields:

* `prefix`: The prefix string (e.g. a line comment).

Usage:

* `lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('--'))`
* `lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('//'))`
* `lex:add_fold_point(
  lexer.KEYWORD, lexer.fold_consecutive_lines('import'))`

<a id="lexer.get_rule"></a>
#### `lexer.get_rule`(lexer, id)

Returns the rule identified by string *id*.

Fields:

* `lexer`: The lexer to fetch a rule from.
* `id`: The id of the rule to fetch.

Return:

* pattern

<a id="lexer.last_char_includes"></a>
#### `lexer.last_char_includes`(s)

Creates and returns a pattern that verifies the first non-whitespace
character behind the current match position is in string set *s*.

Fields:

* `s`: String character set like one passed to `lpeg.S()`.

Usage:

* `local regex = lexer.last_char_includes('+-*!%^&|=,([{') *
  lexer.range('/')`

Return:

* pattern

<a id="lexer.lex"></a>
#### `lexer.lex`(lexer, text, init\_style)

Lexes a chunk of text *text* (that has an initial style number of
*init_style*) using lexer *lexer*, returning a table of token names and
positions.

Fields:

* `lexer`: The lexer to lex text with.
* `text`: The text in the buffer to lex.
* `init_style`: The current style. Multiple-language lexers use this to
  determine which language to start lexing in.

Return:

* table of token names and positions.

<a id="lexer.line_from_position"></a>
#### `lexer.line_from_position`(pos)

Returns the line number (starting from 1) of the line that contains position
*pos*, which starts from 1.

Fields:

* `pos`: The position to get the line number of.

Return:

* number

<a id="lexer.load"></a>
#### `lexer.load`(name, alt\_name, cache)

Initializes or loads and returns the lexer of string name *name*.
Scintilla calls this function in order to load a lexer. Parent lexers also
call this function in order to load child lexers and vice-versa. The user
calls this function in order to load a lexer when using Scintillua as a Lua
library.

Fields:

* `name`: The name of the lexing language.
* `alt_name`: The alternate name of the lexing language. This is useful for
  embedding the same child lexer with multiple sets of start and end tokens.
* `cache`: Flag indicating whether or not to load lexers from the cache.
  This should only be `true` when initially loading a lexer (e.g. not from
  within another lexer for embedding purposes).
  The default value is `false`.

Return:

* lexer object

<a id="lexer.modify_rule"></a>
#### `lexer.modify_rule`(lexer, id, rule)

Replaces in lexer *lexer* the existing rule identified by string *id* with
pattern *rule*.

Fields:

* `lexer`: The lexer to modify.
* `id`: The id associated with this rule.
* `rule`: The LPeg pattern of the rule.

<a id="lexer.new"></a>
#### `lexer.new`(name, opts)

Creates a returns a new lexer with the given name.

Fields:

* `name`: The lexer's name.
* `opts`: Table of lexer options. Options currently supported:
  * `lex_by_line`: Whether or not the lexer only processes whole lines of
    text (instead of arbitrary chunks of text) at a time.
    Line lexers cannot look ahead to subsequent lines.
    The default value is `false`.
  * `fold_by_indentation`: Whether or not the lexer does not define any fold
    points and that fold points should be calculated based on changes in line
    indentation.
    The default value is `false`.
  * `case_insensitive_fold_points`: Whether or not fold points added via
    `lexer.add_fold_point()` ignore case.
    The default value is `false`.
  * `inherit`: Lexer to inherit from.
    The default value is `nil`.

Usage:

* `lexer.new('rhtml', {inherit = lexer.load('html')})`

<a id="lexer.range"></a>
#### `lexer.range`(s, e, single\_line, escapes, balanced)

Creates and returns a pattern that matches a range of text bounded by strings
or patterns *s* and *e*.
This is a convenience function for matching more complicated ranges like
strings with escape characters, balanced parentheses, and block comments
(nested or not). *e* is optional and defaults to *s*. *single_line* indicates
whether or not the range must be on a single line; *escapes* indicates
whether or not to allow '\' as an escape character; and *balanced* indicates
whether or not to handle balanced ranges like parentheses, and requires *s*
and *e* to be different.

Fields:

* `s`: String or pattern start of a range.
* `e`: Optional string or pattern end of a range. The default value is *s*.
* `single_line`: Optional flag indicating whether or not the range must be
  on a single line.
* `escapes`: Optional flag indicating whether or not the range end may
  be escaped by a '\' character.
  The default value is `false` unless *s* and *e* are identical,
  single-character strings. In that case, the default value is `true`.
* `balanced`: Optional flag indicating whether or not to match a balanced
  range, like the "%b" Lua pattern. This flag only applies if *s* and *e* are
  different.

Usage:

* `local dq_str_escapes = lexer.range('"')`
* `local dq_str_noescapes = lexer.range('"', false, false)`
* `local unbalanced_parens = lexer.range('(', ')')`
* `local balanced_parens = lexer.range('(', ')', false, false, true)`

Return:

* pattern

<a id="lexer.starts_line"></a>
#### `lexer.starts_line`(patt)

Creates and returns a pattern that matches pattern *patt* only at the
beginning of a line.

Fields:

* `patt`: The LPeg pattern to match on the beginning of a line.

Usage:

* `local preproc = token(lexer.PREPROCESSOR, lexer.starts_line('#') *
  lexer.nonnewline^0)`

Return:

* pattern

<a id="lexer.to_eol"></a>
#### `lexer.to_eol`(prefix, escape)

Creates and returns a pattern that matches from string or pattern *prefix*
until the end of the line.
*escape* indicates whether the end of the line can be escaped with a '\'
character.

Fields:

* `prefix`: String or pattern prefix to start matching at.
* `escape`: Optional flag indicating whether or not newlines can be escaped
 by a '\' character. The default value is `false`.

Usage:

* `local line_comment = lexer.to_eol('//')`
* `local line_comment = lexer.to_eol(P('#') + ';')`

Return:

* pattern

<a id="lexer.token"></a>
#### `lexer.token`(name, patt)

Creates and returns a token pattern with token name *name* and pattern
*patt*.
If *name* is not a predefined token name, its style must be defined via
`lexer.add_style()`.

Fields:

* `name`: The name of token. If this name is not a predefined token name,
  then a style needs to be assiciated with it via `lexer.add_style()`.
* `patt`: The LPeg pattern associated with the token.

Usage:

* `local ws = token(lexer.WHITESPACE, lexer.space^1)`
* `local annotation = token('annotation', '@' * lexer.word)`

Return:

* pattern

<a id="lexer.word_match"></a>
#### `lexer.word_match`(words, case\_insensitive, word\_chars)

Creates and returns a pattern that matches any single word in string *words*.
*case_insensitive* indicates whether or not to ignore case when matching
words.
This is a convenience function for simplifying a set of ordered choice word
patterns.
If *words* is a multi-line string, it may contain Lua line comments (`--`)
that will ultimately be ignored.

Fields:

* `words`: A string list of words separated by spaces.
* `case_insensitive`: Optional boolean flag indicating whether or not the
  word match is case-insensitive. The default value is `false`.
* `word_chars`: Unused legacy parameter.

Usage:

* `local keyword = token(lexer.KEYWORD, word_match[[foo bar baz]])`
* `local keyword = token(lexer.KEYWORD, word_match([[foo-bar foo-baz
  bar-foo bar-baz baz-foo baz-bar]], true))`

Return:

* pattern


### Tables defined by `lexer`

<a id="lexer.colors"></a>
#### `lexer.colors`

Map of color name strings to color values in `0xBBGGRR` or `"#RRGGBB"`
format.
Note: for applications running within a terminal emulator, only 16 color
values are recognized, regardless of how many colors a user's terminal
actually supports. (A terminal emulator's settings determines how to actually
display these recognized color values, which may end up being mapped to a
completely different color set.) In order to use the light variant of a
color, some terminals require a style's `bold` attribute must be set along
with that normal color. Recognized color values are black (0x000000), red
(0x000080), green (0x008000), yellow (0x008080), blue (0x800000), magenta
(0x800080), cyan (0x808000), white (0xC0C0C0), light black (0x404040), light
red (0x0000FF), light green (0x00FF00), light yellow (0x00FFFF), light blue
(0xFF0000), light magenta (0xFF00FF), light cyan (0xFFFF00), and light white
(0xFFFFFF).

<a id="lexer.styles"></a>
#### `lexer.styles`

Map of style names to style definition tables.

Style names consist of the following default names as well as the token names
defined by lexers.

* `default`: The default style all others are based on.
* `line_number`: The line number margin style.
* `control_char`: The style of control character blocks.
* `indent_guide`: The style of indentation guides.
* `call_tip`: The style of call tip text. Only the `font`, `size`, `fore`,
  and `back` style definition fields are supported.
* `fold_display_text`: The style of text displayed next to folded lines.
* `class`, `comment`, `constant`, `embedded`, `error`, `function`,
  `identifier`, `keyword`, `label`, `number`, `operator`, `preprocessor`,
  `regex`, `string`, `type`, `variable`, `whitespace`: Some token names used
  by lexers. Some lexers may define more token names, so this list is not
  exhaustive.

Style definition tables may contain the following fields:

* `font`: String font name.
* `size`: Integer font size.
* `bold`: Whether or not the font face is bold. The default value is `false`.
* `weight`: Integer weight or boldness of a font, between 1 and 999.
* `italics`: Whether or not the font face is italic. The default value is
  `false`.
* `underlined`: Whether or not the font face is underlined. The default value
  is `false`.
* `fore`: Font face foreground color in `0xBBGGRR` or `"#RRGGBB"` format.
* `back`: Font face background color in `0xBBGGRR` or `"#RRGGBB"` format.
* `eolfilled`: Whether or not the background color extends to the end of the
  line. The default value is `false`.
* `case`: Font case, `'u'` for upper, `'l'` for lower, and `'m'` for normal,
  mixed case. The default value is `'m'`.
* `visible`: Whether or not the text is visible. The default value is `true`.
* `changeable`: Whether the text is changeable instead of read-only. The
  default value is `true`.

- - -

