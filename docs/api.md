# Scintillua API Documentation

<a id="lexer"></a>
## The `lexer` module

Lexes Scintilla documents and source code with Lua and LPeg.


### Contents

1. [Writing Lua Lexers](#writing-lua-lexers)
2. [Lexer Basics](#lexer-basics)
  - [New Lexer Template](#new-lexer-template)
  - [Tags](#tags)
  - [Rules](#rules)
  - [Summary](#summary)
3. [Advanced Techniques](#advanced-techniques)
  - [Line Lexers](#line-lexers)
  - [Embedded Lexers](#embedded-lexers)
  - [Lexers with Complex State](#lexers-with-complex-state)
4. [Code Folding](#code-folding)
5. [Using Lexers](#using-lexers)
6. [Migrating Legacy Lexers](#migrating-legacy-lexers)
7. [Considerations](#considerations)
8. [API Documentation](#lexer.add_fold_point)

### Writing Lua Lexers

Lexers recognize and tag elements of source code for syntax highlighting. Scintilla (the
editing component behind [Textadept][] and [SciTE][]) traditionally uses static, compiled C++
lexers which are difficult to create and/or extend. On the other hand, Lua makes it easy to
to rapidly create new lexers, extend existing ones, and embed lexers within one another. Lua
lexers tend to be more readable than C++ lexers too.

While lexers can be written in plain Lua, Scintillua prefers using Parsing Expression
Grammars, or PEGs, composed with the Lua [LPeg library][]. As a result, this document is
devoted to writing LPeg lexers. The following table comes from the LPeg documentation and
summarizes all you need to know about constructing basic LPeg patterns. This module provides
convenience functions for creating and working with other more advanced patterns and concepts.

Operator | Description
-|-
`lpeg.P`(*string*) | Matches string *string* literally.
`lpeg.P`(*n*) | Matches exactly *n* number of characters.
`lpeg.S`(*string*) | Matches any character in string set *string*.
`lpeg.R`("*xy*") | Matches any character between range *x* and *y*.
*patt*`^`*n* | Matches at least *n* repetitions of *patt*.
*patt*`^`-*n* | Matches at most *n* repetitions of *patt*.
*patt1* `*` *patt2* | Matches *patt1* followed by *patt2*.
*patt1* `+` *patt2* | Matches *patt1* or *patt2* (ordered choice).
*patt1* `-` *patt2* | Matches *patt1* if *patt2* does not also match.
`-`*patt* | Matches if *patt* does not match, consuming no input.
`#`*patt* | Matches *patt* but consumes no input.

The first part of this document deals with rapidly constructing a simple lexer. The next part
deals with more advanced techniques, such as embedding lexers within one another. Following
that is a discussion about code folding, or being able to tell Scintilla which code blocks
are "foldable" (temporarily hideable from view). After that are instructions on how to use
Lua lexers with the aforementioned Textadept and SciTE editors. Finally there are comments
on lexer performance and limitations.

[LPeg library]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
[Textadept]: https://orbitalquark.github.io/textadept
[SciTE]: https://scintilla.org/SciTE.html

### Lexer Basics

The *lexers/* directory contains all of Scintillua's Lua lexers, including any new ones you
write. Before attempting to write one from scratch though, first determine if your programming
language is similar to any of the 100+ languages supported. If so, you may be able to copy
and modify, or inherit from that lexer, saving some time and effort. The filename of your
lexer should be the name of your programming language in lower case followed by a *.lua*
extension. For example, a new Lua lexer has the name *lua.lua*.

#### New Lexer Template

There is a *lexers/template.txt* file that contains a simple template for a new lexer. Feel
free to use it, replacing the '?' with the name of your lexer. Consider this snippet from
the template:

```lua
-- ? LPeg lexer.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

--[[... lexer rules ...]]

-- Identifier.
local identifier = lex:tag(lexer.IDENTIFIER, lexer.word)
lex:add_rule('identifier', identifier)

--[[... more lexer rules ...]]

return lex
```

The first line of code is a Lua convention to store a global variable into a local variable
for quick access. The second line simply defines often used convenience variables. The third
and last lines [define](#lexer.new) and return the lexer object Scintillua uses; they are
very important and must be part of every lexer. Note the `...` passed to [`lexer.new()`](#lexer.new) is
literal: the lexer will assume the name of its filename or an alternative name specified
by [`lexer.load()`](#lexer.load) in embedded lexer applications. The fourth line uses something called a
"tag", an essential component of lexers. You will learn about tags shortly. The fifth line
defines a lexer grammar rule, which you will learn about later. (Be aware that it is common
practice to combine these two lines for short rules.)  Note, however, the `local` prefix in
front of variables, which is needed so-as not to affect Lua's global environment. All in all,
this is a minimal, working lexer that you can build on.

#### Tags

Take a moment to think about your programming language's structure. What kind of key elements
does it have? Most languages have elements like keywords, strings, and comments. The
lexer's job is to break down source code into these elements and "tag" them for syntax
highlighting. Therefore, tags are an essential component of lexers. It is up to you how
specific your lexer is when it comes to tagging elements. Perhaps only distinguishing between
keywords and identifiers is necessary, or maybe recognizing constants and built-in functions,
methods, or libraries is desirable. The Lua lexer, for example, tags the following elements:
keywords, functions, constants, identifiers, strings, comments, numbers, labels, attributes,
and operators. Even though functions and constants are subsets of identifiers, Lua programmers
find it helpful for the lexer to distinguish between them all. It is perfectly acceptable
to just recognize keywords and identifiers.

In a lexer, LPeg patterns that match particular sequences of characters are tagged with a
tag name using the the [`lexer.tag()`](#lexer.tag) function. Let us examine the "identifier" tag used in
the template shown earlier:

```lua
local identifier = lex:tag(lexer.IDENTIFIER, lexer.word)
```

At first glance, the first argument does not appear to be a string name and the second
argument does not appear to be an LPeg pattern. Perhaps you expected something like:

```lua
lex:tag('identifier', (lpeg.R('AZ', 'az')  + '_') * (lpeg.R('AZ', 'az', '09') + '_')^0)
```

The [`lexer`](#lexer) module actually provides a convenient list of common tag names and common LPeg
patterns for you to use. Tag names for programming languages include (but are not limited
to) `lexer.DEFAULT`, `lexer.COMMENT`, `lexer.STRING`, `lexer.NUMBER`, `lexer.KEYWORD`,
`lexer.IDENTIFIER`, `lexer.OPERATOR`, `lexer.ERROR`, `lexer.PREPROCESSOR`, `lexer.CONSTANT`,
`lexer.CONSTANT_BUILTIN`, `lexer.VARIABLE`, `lexer.VARIABLE_BUILTIN`, `lexer.FUNCTION`,
`lexer.FUNCTION_BUILTIN`, `lexer.FUNCTION_METHOD`, `lexer.CLASS`, `lexer.TYPE`, `lexer.LABEL`,
`lexer.REGEX`, `lexer.EMBEDDED`, and `lexer.ANNOTATION`. Tag names for markup languages include
(but are not limited to) `lexer.TAG`, `lexer.ATTRIBUTE`, `lexer.HEADING`, `lexer.BOLD`,
`lexer.ITALIC`, `lexer.UNDERLINE`, `lexer.CODE`, `lexer.LINK`, `lexer.REFERENCE`, and
`lexer.LIST`. Patterns include [`lexer.any`](#lexer.any), [`lexer.alpha`](#lexer.alpha), [`lexer.digit`](#lexer.digit), [`lexer.alnum`](#lexer.alnum),
[`lexer.lower`](#lexer.lower), [`lexer.upper`](#lexer.upper), [`lexer.xdigit`](#lexer.xdigit), [`lexer.graph`](#lexer.graph), [`lexer.punct`](#lexer.punct), [`lexer.space`](#lexer.space),
[`lexer.newline`](#lexer.newline), [`lexer.nonnewline`](#lexer.nonnewline), [`lexer.dec_num`](#lexer.dec_num), [`lexer.hex_num`](#lexer.hex_num), [`lexer.oct_num`](#lexer.oct_num),
[`lexer.bin_num`](#lexer.bin_num), [`lexer.integer`](#lexer.integer), [`lexer.float`](#lexer.float), [`lexer.number`](#lexer.number), and [`lexer.word`](#lexer.word). You may use
your own tag names if none of the above fit your language, but an advantage to using predefined
tag names is that the language elements your lexer recognizes will inherit any universal syntax
highlighting color theme that your editor uses. You can also "subclass" existing tag names by
appending a '.*subclass*' string to them. For example, the HTML lexer tags unknown tags as
`lexer.TAG .. '.unknown'`. This gives editors the opportunity to highlight those subclassed
tags in a different way than normal tags, or fall back to highlighting them as normal tags.

##### Example Tags

So, how might you recognize and tag elements like keywords, comments, and strings?  Here are
some examples.

**Keywords**

Instead of matching *n* keywords with *n* `P('keyword_n')` ordered choices, use one
of of the following methods:

1. Use the convenience function [`lexer.word_match()`](#lexer.word_match) optionally coupled with
   [`lexer.set_word_list()`](#lexer.set_word_list). It is much easier and more efficient to write word matches like:

   ```lua
   local keyword = lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD))
   --[[...]]
   lex:set_word_list(lexer.KEYWORD, {
     'keyword_1', 'keyword_2', ..., 'keyword_n'
   })

   local case_insensitive_word = lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD, true))
   --[[...]]
   lex:set_word_list(lexer.KEYWORD, {
     'KEYWORD_1', 'keyword_2', ..., 'KEYword_n'
   })

   local hyphenated_keyword = lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD))
   --[[...]]
   lex:set_word_list(lexer.KEYWORD, {
     'keyword-1', 'keyword-2', ..., 'keyword-n'
   })
   ```

   The benefit of using this method is that other lexers that inherit from, embed, or embed
   themselves into your lexer can set, replace, or extend these word lists. For example,
   the TypeScript lexer inherits from JavaScript, but extends JavaScript's keyword and type
   lists with more options.

   This method also allows applications that use your lexer to extend or replace your word
   lists. For example, the Lua lexer includes keywords and functions for the latest version
   of Lua (5.4 at the time of writing). However, editors using that lexer might want to use
   keywords from Lua version 5.1, which is still quite popular.

   Note that calling `lex:set_word_list()` is completely optional. Your lexer is allowed to
   expect the editor using it to supply word lists. Scintilla-based editors can do so via
   Scintilla's `ILexer5` interface.

2. Use the lexer-agnostic form of [`lexer.word_match()`](#lexer.word_match):

   ```lua
   local keyword = lex:tag(lexer.KEYWORD, lexer.word_match{
     'keyword_1', 'keyword_2', ..., 'keyword_n'
   })

   local case_insensitive_keyword = lex:tag(lexer.KEYWORD, lexer.word_match({
     'KEYWORD_1', 'keyword_2', ..., 'KEYword_n'
   }, true))

   local hyphened_keyword = lex:tag(lexer.KEYWORD, lexer.word_match{
     'keyword-1', 'keyword-2', ..., 'keyword-n'
   })
   ```

   For short keyword lists, you can use a single string of words. For example:

   ```lua
   local keyword = lex:tag(lexer.KEYWORD, lexer.word_match('key_1 key_2 ... key_n'))
   ```

   You can use this method for static word lists that do not change, or where it does not
   make sense to allow applications or other lexers to extend or replace a word list.

**Comments**

Line-style comments with a prefix character(s) are easy to express:

```lua
local shell_comment = lex:tag(lexer.COMMENT, lexer.to_eol('#'))
local c_line_comment = lex:tag(lexer.COMMENT, lexer.to_eol('//', true))
```

The comments above start with a '#' or "//" and go to the end of the line (EOL). The second
comment recognizes the next line also as a comment if the current line ends with a '\\'
escape character.

C-style "block" comments with a start and end delimiter are also easy to express:

```lua
local c_comment = lex:tag(lexer.COMMENT, lexer.range('/*', '*/'))
```

This comment starts with a "/\*" sequence and contains anything up to and including an ending
"\*/" sequence. The ending "\*/" is optional so the lexer can recognize unfinished comments
as comments and highlight them properly.

**Strings**

Most programming languages allow escape sequences in strings such that a sequence like
"\\&quot;" in a double-quoted string indicates that the '&quot;' is not the end of the
string. [`lexer.range()`](#lexer.range) handles escapes inherently.

```lua
local dq_str = lexer.range('"')
local sq_str = lexer.range("'")
local string = lex:tag(lexer.STRING, dq_str + sq_str)
```

In this case, the lexer treats '\\' as an escape character in a string sequence.

**Numbers**

Most programming languages have the same format for integers and floats, so it might be as
simple as using a predefined LPeg pattern:

```lua
local number = lex:tag(lexer.NUMBER, lexer.number)
```

However, some languages allow postfix characters on integers:

```lua
local integer = P('-')^-1 * (lexer.dec_num * S('lL')^-1)
local number = lex:tag(lexer.NUMBER, lexer.float + lexer.hex_num + integer)
```

Other languages allow separaters within numbers for better readability:

```lua
local number = lex:tag(lexer.NUMBER, lexer.number_('_')) -- recognize 1_000_000
```

Your language may need other tweaks, but it is up to you how fine-grained you want your
highlighting to be. After all, you are not writing a compiler or interpreter!

#### Rules

Programming languages have grammars, which specify valid syntactic structure. For example,
comments usually cannot appear within a string, and valid identifiers (like variable names)
cannot be keywords. In Lua lexers, grammars consist of LPeg pattern rules, many of which
are tagged.  Recall from the lexer template the [`lexer.add_rule()`](#lexer.add_rule) call, which adds a rule
to the lexer's grammar:

```lua
lex:add_rule('identifier', identifier)
```

Each rule has an associated name, but rule names are completely arbitrary and serve only to
identify and distinguish between different rules. Rule order is important: if text does not
match the first rule added to the grammar, the lexer tries to match the second rule added, and
so on. Right now this lexer simply matches identifiers under a rule named "identifier".

To illustrate the importance of rule order, here is an example of a simplified Lua lexer:

```lua
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, ...))
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, ...))
lex:add_rule('string', lex:tag(lexer.STRING, ...))
lex:add_rule('comment', lex:tag(lexer.COMMENT, ...))
lex:add_rule('number', lex:tag(lexer.NUMBER, ...))
lex:add_rule('label', lex:tag(lexer.LABEL, ...))
lex:add_rule('operator', lex:tag(lexer.OPERATOR, ...))
```

Notice how identifiers come _after_ keywords. In Lua, as with most programming languages,
the characters allowed in keywords and identifiers are in the same set (alphanumerics plus
underscores). If the lexer added the "identifier" rule before the "keyword" rule, all keywords
would match identifiers and thus would be incorrectly tagged (and likewise incorrectly
highlighted) as identifiers instead of keywords. The same idea applies to function names,
constants, etc. that you may want to distinguish between: their rules should come before
identifiers.

So what about text that does not match any rules? For example in Lua, the '!' character is
meaningless outside a string or comment. Normally the lexer skips over such text. If instead
you want to highlight these "syntax errors", add a final rule:

```lua
lex:add_rule('keyword', keyword)
--[[...]]
lex:add_rule('error', lex:tag(lexer.ERROR, lexer.any))
```

This identifies and tags any character not matched by an existing rule as a `lexer.ERROR`.

Even though the rules defined in the examples above contain a single tagged pattern, rules may
consist of multiple tagged patterns. For example, the rule for an HTML tag could consist of a
tagged tag followed by an arbitrary number of tagged attributes, separated by whitespace. This
allows the lexer to produce all tags separately, but in a single, convenient rule. That rule
might look something like this:

```lua
local ws = lex:get_rule('whitespace') -- predefined rule for all lexers
lex:add_rule('tag', tag_start * (ws * attributes)^0 * tag_end^-1)
```

Note however that lexers with complex rules like these are more prone to lose track of their
state, especially if they span multiple lines.

#### Summary

Lexers primarily consist of tagged patterns and grammar rules. These patterns match language
elements like keywords, comments, and strings, and rules dictate the order in which patterns
are matched. At your disposal are a number of convenience patterns and functions for rapidly
creating a lexer. If you choose to use predefined tag names (or perhaps even subclassed
names) for your patterns, you do not have to update your editor's theme to specify how to
syntax-highlight those patterns. Your language's elements will inherit the default syntax
highlighting color theme your editor uses.

### Advanced Techniques

#### Line Lexers

By default, lexers match the arbitrary chunks of text passed to them by Scintilla. These
chunks may be a full document, only the visible part of a document, or even just portions of
lines. Some lexers need to match whole lines. For example, a lexer for the output of a file
"diff" needs to know if the line started with a '+' or '-' and then highlight the entire
line accordingly. To indicate that your lexer matches by line, create the lexer with an
extra parameter:

```lua
local lex = lexer.new(..., {lex_by_line = true})
```

Now the input text for the lexer is a single line at a time. Keep in mind that line lexers
do not have the ability to look ahead to subsequent lines.

#### Embedded Lexers

Scintillua lexers embed within one another very easily, requiring minimal effort. In the
following sections, the lexer being embedded is called the "child" lexer and the lexer a child
is being embedded in is called the "parent". For example, consider an HTML lexer and a CSS
lexer. Either lexer stands alone for tagging their respective HTML and CSS files. However, CSS
can be embedded inside HTML. In this specific case, the CSS lexer is the "child" lexer with
the HTML lexer being the "parent". Now consider an HTML lexer and a PHP lexer. This sounds
a lot like the case with CSS, but there is a subtle difference: PHP _embeds itself into_
HTML while CSS is _embedded in_ HTML. This fundamental difference results in two types of
embedded lexers: a parent lexer that embeds other child lexers in it (like HTML embedding CSS),
and a child lexer that embeds itself into a parent lexer (like PHP embedding itself in HTML).

##### Parent Lexer

Before embedding a child lexer into a parent lexer, the parent lexer needs to load the child
lexer. This is done with the [`lexer.load()`](#lexer.load) function. For example, loading the CSS lexer
within the HTML lexer looks like:

```lua
local css = lexer.load('css')
```

The next part of the embedding process is telling the parent lexer when to switch over
to the child lexer and when to switch back. The lexer refers to these indications as the
"start rule" and "end rule", respectively, and are just LPeg patterns. Continuing with the
HTML/CSS example, the transition from HTML to CSS is when the lexer encounters a "style"
tag with a "type" attribute whose value is "text/css":

```lua
local css_tag = P('<style') * P(function(input, index)
  if input:find('^[^>]+type="text/css"', index) then return true end
end)
```

This pattern looks for the beginning of a "style" tag and searches its attribute list for
the text "`type="text/css"`". (In this simplified example, the Lua pattern does not consider
whitespace between the '=' nor does it consider that using single quotes is valid.) If there
is a match, the functional pattern returns `true`. However, we ultimately want to tag the
"style" tag as an HTML tag, so the actual start rule looks like this:

```lua
local css_start_rule = #css_tag * tag
```

Now that the parent knows when to switch to the child, it needs to know when to switch
back. In the case of HTML/CSS, the switch back occurs when the lexer encounters an ending
"style" tag, though the lexer should still tag that tag as an HTML tag:

```lua
local css_end_rule = #P('</style>') * tag
```

Once the parent loads the child lexer and defines the child's start and end rules, it embeds
the child with the [`lexer.embed()`](#lexer.embed) function:

```lua
lex:embed(css, css_start_rule, css_end_rule)
```

##### Child Lexer

The process for instructing a child lexer to embed itself into a parent is very similar to
embedding a child into a parent: first, load the parent lexer into the child lexer with the
[`lexer.load()`](#lexer.load) function and then create start and end rules for the child lexer. However,
in this case, call [`lexer.embed()`](#lexer.embed) with switched arguments. For example, in the PHP lexer:

```lua
local html = lexer.load('html')
local php_start_rule = lex:tag('php_tag', '<?php' * lexer.space)
local php_end_rule = lex:tag('php_tag', '?>')
html:embed(lex, php_start_rule, php_end_rule)
```

Note that the use of a 'php_tag' tag will require the editor using the lexer to specify how
to highlight text with that tag. In order to avoid this, you could use the `lexer.PREPROCESSOR`
tag instead.

#### Lexers with Complex State

A vast majority of lexers are not stateful and can operate on any chunk of text in a
document. However, there may be rare cases where a lexer does need to keep track of some
sort of persistent state. Rather than using `lpeg.P` function patterns that set state
variables, it is recommended to make use of Scintilla's built-in, per-line state integers via
[`lexer.line_state`](#lexer.line_state). It was designed to accommodate up to 32 bit-flags for tracking state.
[`lexer.line_from_position()`](#lexer.line_from_position) will return the line for any position given to an `lpeg.P`
function pattern. (Any positions derived from that position argument will also work.)

Writing stateful lexers is beyond the scope of this document.

### Code Folding

When reading source code, it is occasionally helpful to temporarily hide blocks of code like
functions, classes, comments, etc. This is the concept of "folding". In the Textadept and
SciTE editors for example, little markers in the editor margins appear next to code that
can be folded at places called "fold points". When the user clicks on one of those markers,
the editor hides the code associated with the marker until the user clicks on the marker
again. The lexer specifies these fold points and what code exactly to fold.

The fold points for most languages occur on keywords or character sequences. Examples of
fold keywords are "if" and "end" in Lua and examples of fold character sequences are '{',
'}', "/\*", and "\*/" in C for code block and comment delimiters, respectively. However,
these fold points cannot occur just anywhere. For example, lexers should not recognize fold
keywords that appear within strings or comments. The [`lexer.add_fold_point()`](#lexer.add_fold_point) function allows
you to conveniently define fold points with such granularity. For example, consider C:

```lua
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
```

The first assignment states that any '{' or '}' that the lexer tagged as an `lexer.OPERATOR`
is a fold point. Likewise, the second assignment states that any "/\*" or "\*/" that the
lexer tagged as part of a `lexer.COMMENT` is a fold point. The lexer does not consider any
occurrences of these characters outside their tagged elements (such as in a string) as fold
points. How do you specify fold keywords? Here is an example for Lua:

```lua
lex:add_fold_point(lexer.KEYWORD, 'if', 'end')
lex:add_fold_point(lexer.KEYWORD, 'do', 'end')
lex:add_fold_point(lexer.KEYWORD, 'function', 'end')
lex:add_fold_point(lexer.KEYWORD, 'repeat', 'until')
```

If your lexer has case-insensitive keywords as fold points, simply add a
`case_insensitive_fold_points = true` option to [`lexer.new()`](#lexer.new), and specify keywords in
lower case.

If your lexer needs to do some additional processing in order to determine if a tagged element
is a fold point, pass a function to `lex:add_fold_point()` that returns an integer. A return
value of `1` indicates the element is a beginning fold point and a return value of `-1`
indicates the element is an ending fold point. A return value of `0` indicates the element
is not a fold point. For example:

```lua
local function fold_strange_element(text, pos, line, s, symbol)
  if ... then
    return 1 -- beginning fold point
  elseif ... then
    return -1 -- ending fold point
  end
  return 0
end

lex:add_fold_point('strange_element', '|', fold_strange_element)
```

Any time the lexer encounters a '|' that is tagged as a "strange_element", it calls the
`fold_strange_element` function to determine if '|' is a fold point. The lexer calls these
functions with the following arguments: the text to identify fold points in, the beginning
position of the current line in the text to fold, the current line's text, the position in
the current line the fold point text starts at, and the fold point text itself.

#### Fold by Indentation

Some languages have significant whitespace and/or no delimiters that indicate fold points. If
your lexer falls into this category and you would like to mark fold points based on changes
in indentation, create the lexer with a `fold_by_indentation = true` option:

```lua
local lex = lexer.new(..., {fold_by_indentation = true})
```

### Using Lexers

**Textadept**

Place your lexer in your *~/.textadept/lexers/* directory so you do not overwrite it when
upgrading Textadept. Also, lexers in this directory override default lexers. Thus, Textadept
loads a user *lua* lexer instead of the default *lua* lexer. This is convenient for tweaking
a default lexer to your liking. Then add a [file extension](#lexer.detect_extensions) for
your lexer if necessary.

**SciTE**

Create a *.properties* file for your lexer and `import` it in either your *SciTEUser.properties*
or *SciTEGlobal.properties*. The contents of the *.properties* file should contain:

	file.patterns.[lexer_name]=[file_patterns]
	lexer.$(file.patterns.[lexer_name])=scintillua.[lexer_name]
	keywords.$(file.patterns.[lexer_name])=scintillua
	keywords2.$(file.patterns.[lexer_name])=scintillua
	...
	keywords9.$(file.patterns.[lexer_name])=scintillua

where `[lexer_name]` is the name of your lexer (minus the *.lua* extension) and
`[file_patterns]` is a set of file extensions to use your lexer for. The `keyword` settings are
only needed if another SciTE properties file has defined keyword sets for `[file_patterns]`.
The `scintillua` keyword setting instructs Scintillua to use the keyword sets defined within
the lexer. You can override a lexer's keyword set(s) by specifying your own in the same order
that the lexer calls `lex:set_word_list()`. For example, the Lua lexer's first set of keywords
is for reserved words, the second is for built-in global functions, the third is for library
functions, the fourth is for built-in global constants, and the fifth is for library constants.

SciTE assigns styles to tag names in order to perform syntax highlighting. Since the set of
tag names used for a given language changes, your *.properties* file should specify styles
for tag names instead of style numbers. For example:

	scintillua.styles.my_tag=$(scintillua.styles.keyword),bold

### Migrating Legacy Lexers

Legacy lexers are of the form:

```lua
local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, S = lpeg.P, lpeg.S

local lex = lexer.new('?')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match{
  --[[...]]
}))

--[[... other rule definitions ...]]

-- Custom.
lex:add_rule('custom_rule', token('custom_token', ...))
lex:add_style('custom_token', lexer.styles.keyword .. {bold = true})

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')

return lex
```

While Scintillua will mostly handle such legacy lexers just fine without any changes, it is
recommended that you migrate yours. The migration process is fairly straightforward:

1. [`lexer`](#lexer) exists in the default lexer environment, so `require('lexer')` should be replaced
   by simply [`lexer`](#lexer). (Keep in mind `local lexer = lexer` is a Lua idiom.)
2. Every lexer created using [`lexer.new()`](#lexer.new) should no longer specify a lexer name by string,
   but should instead use `...` (three dots), which evaluates to the lexer's filename or
   alternative name in embedded lexer applications.
3. Every lexer created using [`lexer.new()`](#lexer.new) now includes a rule to match whitespace. Unless
   your lexer has significant whitespace, you can remove your legacy lexer's whitespace
   token and rule. Otherwise, your defined whitespace rule will replace the default one.
4. The concept of tokens has been replaced with tags. Instead of calling a `token()` function,
   call [`lex:tag()`](#lexer.tag) instead.
5. Lexers now support replaceable word lists. Instead of calling [`lexer.word_match()`](#lexer.word_match) with
   large word lists, call it as an instance method with an identifier string (typically
   something like `lexer.KEYWORD`). Then at the end of the lexer (before `return lex`), call
   [`lex:set_word_list()`](#lexer.set_word_list) with the same identifier and the usual
   list of words to match. This allows users of your lexer to call `lex:set_word_list()`
   with their own set of words should they wish to.
6. Lexers no longer specify styling information. Remove any calls to `lex:add_style()`. You
   may need to add styling information for custom tags to your editor's theme.
7. `lexer.last_char_includes()` has been deprecated in favor of the new [`lexer.after_set()`](#lexer.after_set).
   Use the character set and pattern as arguments to that new function.

As an example, consider the following sample legacy lexer:

```lua
local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, S = lpeg.P, lpeg.S

local lex = lexer.new('legacy')

lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))
lex:add_rule('keyword', token(lexer.KEYWORD, word_match('foo bar baz')))
lex:add_rule('custom', token('custom', 'quux'))
lex:add_style('custom', lexer.styles.keyword .. {bold = true})
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))
lex:add_rule('string', token(lexer.STRING, lexer.range('"')))
lex:add_rule('comment', token(lexer.COMMENT, lexer.to_eol('#')))
lex:add_rule('number', token(lexer.NUMBER, lexer.number))
lex:add_rule('operator', token(lexer.OPERATOR, S('+-*/%^=<>,.()[]{}')))

lex:add_fold_point(lexer.OPERATOR, '{', '}')

return lex
```

Following the migration steps would yield:

```lua
local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))
lex:add_rule('custom', lex:tag('custom', 'quux'))
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))
lex:add_rule('string', lex:tag(lexer.STRING, lexer.range('"')))
lex:add_rule('comment', lex:tag(lexer.COMMENT, lexer.to_eol('#')))
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number))
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('+-*/%^=<>,.()[]{}')))

lex:add_fold_point(lexer.OPERATOR, '{', '}')

lex:set_word_list(lexer.KEYWORD, {'foo', 'bar', 'baz'})

return lex
```

Any editors using this lexer would have to add a style for the 'custom' tag.

### Considerations

#### Performance

There might be some slight overhead when initializing a lexer, but loading a file from disk
into Scintilla is usually more expensive. Actually painting the syntax highlighted text to
the screen is often more expensive than the lexing operation. On modern computer systems,
I see no difference in speed between Lua lexers and Scintilla's C++ ones. Optimize lexers for
speed by re-arranging [`lexer.add_rule()`](#lexer.add_rule) calls so that the most common rules match first. Do
keep in mind that order matters for similar rules.

In some cases, folding may be far more expensive than lexing, particularly in lexers with a
lot of potential fold points. If your lexer is exhibiting signs of slowness, try disabling
folding in your text editor first. If that speeds things up, you can try reducing the number
of fold points you added, overriding [`lexer.fold()`](#lexer.fold) with your own implementation, or simply
eliminating folding support from your lexer.

#### Limitations

Embedded preprocessor languages like PHP cannot completely embed themselves into their parent
languages because the parent's tagged patterns do not support start and end rules. This
mostly goes unnoticed, but code like

```php
    <div id="<?php echo $id; ?>">
```

will not be tagged correctly. Also, these types of languages cannot currently embed themselves
into their parent's child languages either.

A language cannot embed itself into something like an interpolated string because it is
possible that if lexing starts within the embedded entity, it will not be detected as such,
so a child to parent transition cannot happen. For example, the following Ruby code will
not be tagged correctly:

```ruby
    sum = "1 + 2 = #{1 + 2}"
```

Also, there is the potential for recursion for languages embedding themselves within themselves.

#### Troubleshooting

Errors in lexers can be tricky to debug. Lexers print Lua errors to `io.stderr` and `_G.print()`
statements to `io.stdout`. Running your editor from a terminal is the easiest way to see
errors as they occur.

#### Risks

Poorly written lexers have the ability to crash Scintilla (and thus its containing application),
so unsaved data might be lost. However, I have only observed these crashes in early lexer
development, when syntax errors or pattern errors are present. Once the lexer actually
starts processing and tagging text (either correctly or incorrectly, it does not matter),
I have not observed any crashes.

#### Acknowledgements

Thanks to Peter Odding for his [lexer post][] on the Lua mailing list that provided inspiration,
and thanks to Roberto Ierusalimschy for LPeg.

[lexer post]: http://lua-users.org/lists/lua-l/2007-04/msg00116.html

<a id="lexer.add_fold_point"></a>
### `lexer.add_fold_point`(*lexer*, *tag_name*, *start_symbol*, *end_symbol*)

Adds a fold point to a lexer.

Parameters:
- *lexer*:  Lexer to add a fold point to.
- *tag_name*:  String tag name of fold point text.
- *start_symbol*:  String fold point start text.
- *end_symbol*:  Either string fold point end text, or a function that returns whether or
   not *start_symbol* is a beginning fold point (1), an ending fold point (-1), or not a fold
   point at all (0). If it is a function, it is passed the following arguments:
   - `text`: The text being processed for fold points.
   - `pos`: The position in *text* of the beginning of the line currently being processed.
   - `line`: The text of the line currently being processed.
   - `s`: The position of *start_symbol* in *line*.
   - `symbol`: *start_symbol* itself.

Usage:

```lua
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.KEYWORD, 'if', 'end')
lex:add_fold_point('custom', function(text, pos, line, s, symbol) ... end)
```

<a id="lexer.add_rule"></a>
### `lexer.add_rule`(*lexer*, *id*, *rule*)

Adds a rule to a lexer.

Parameters:
- *lexer*:  Lexer to add *rule* to.
- *id*:  String id associated with this rule. It does not have to be the same as the name
   passed to `lex:tag()`.
- *rule*:  LPeg pattern of the rule to add.

<a id="lexer.after_set"></a>
### `lexer.after_set`(*set*, *patt*, *skip*)

Returns a pattern that only matches when it comes after certain characters (or when there
are no characters behind it).

Parameters:
- *set*:  String character set like one passed to `lpeg.S()`.
- *patt*:  LPeg pattern to match after a character in *set*.
- *skip*:  String character set to skip over when looking backwards from *patt*. The default
   value is " \t\r\n\v\f" (whitespace).

Usage:

```lua
local regex = lexer.after_set('+-*!%^&|=,([{', lexer.range('/'))
   -- matches "var re = /foo/;", but not "var x = 1 / 2 / 3;"
```

<a id="lexer.alnum"></a>
### `lexer.alnum`

A pattern that matches any alphanumeric character ('A'-'Z', 'a'-'z', '0'-'9').

<a id="lexer.alpha"></a>
### `lexer.alpha`

A pattern that matches any alphabetic character ('A'-'Z', 'a'-'z').

<a id="lexer.any"></a>
### `lexer.any`

A pattern that matches any single character.

<a id="lexer.bin_num"></a>
### `lexer.bin_num`

A pattern that matches a binary number.

<a id="lexer.bin_num_"></a>
### `lexer.bin_num_`(*c*)

Returns a pattern that matches a binary number, whose digits may be separated by a particular
character.

Parameters:
- *c*:  Digit separator character.

<a id="lexer.dec_num"></a>
### `lexer.dec_num`

A pattern that matches a decimal number.

<a id="lexer.dec_num_"></a>
### `lexer.dec_num_`(*c*)

Returns a pattern that matches a decimal number, whose digits may be separated by a particular
character.

Parameters:
- *c*:  Digit separator character.

<a id="lexer.detect"></a>
### `lexer.detect`([*filename*[, *line*]])

Returns the name of the lexer often associated a particular filename and/or file content.

Parameters:
- *filename*:  String filename to inspect. The default value is read from the
   "lexer.scintillua.filename" property.
- *line*:  String first content line, such as a shebang line. The default value
   is read from the "lexer.scintillua.line" property.

Returns: string lexer name to pass to [`lexer.load()`](#lexer.load), or `nil` if none was detected

<a id="lexer.detect_extensions"></a>
### `lexer.detect_extensions`

Map of file extensions, without the '.' prefix, to their associated lexer names.

Usage:

```lua
lexer.detect_extensions.luadoc = 'lua'
```

<a id="lexer.detect_patterns"></a>
### `lexer.detect_patterns`

Map of first-line patterns to their associated lexer names.

These are Lua string patterns, not LPeg patterns.

Usage:

```lua
lexer.detect_patterns['^#!.+/zsh'] = 'bash'
```

<a id="lexer.digit"></a>
### `lexer.digit`

A pattern that matches any digit ('0'-'9').

<a id="lexer.embed"></a>
### `lexer.embed`(*lexer*, *child*, *start_rule*, *end_rule*)

Embeds a child lexer into a parent lexer.

Parameters:
- *lexer*:  Parent lexer.
- *child*:  Child lexer.
- *start_rule*:  LPeg pattern matches the beginning of the child lexer.
- *end_rule*:  LPeg pattern that matches the end of the child lexer.

Usage:

```lua
html:embed(css, css_start_rule, css_end_rule)
html:embed(lex, php_start_rule, php_end_rule) -- from php lexer
```

<a id="lexer.float"></a>
### `lexer.float`

A pattern that matches a floating point number.

<a id="lexer.float_"></a>
### `lexer.float_`(*c*)

Returns a pattern that matches a floating point number, whose digits may be separated by a
particular character.

Parameters:
- *c*:  Digit separator character.

<a id="lexer.fold"></a>
### `lexer.fold`(*lexer*, *text*, *start_line*, *start_level*)

Determines fold points in a chunk of text.

Parameters:
- *lexer*:  Lexer to fold text with.
- *text*:  String text to fold, which may be a partial chunk, single line, or full text.
- *start_line*:  Line number *text* starts on, counting from 1.
- *start_level*:  Fold level *text* starts with. It cannot be lower than `lexer.FOLD_BASE`
   (1024).

Returns: table of line numbers mapped to fold levels

Usage:

```lua
lex:fold(...) --> {[1] = 1024, [2] = 9216, [3] = 1025, [4] = 1025, [5] = 1024}
```

<a id="lexer.fold_level"></a>
### `lexer.fold_level`

Map of line numbers (starting from 1) to their fold level bit-masks.
(Read-only)
Fold level masks are composed of an integer level combined with any of the following bits:

  - `lexer.FOLD_BASE`
    The initial fold level (1024).
  - `lexer.FOLD_BLANK`
    The line is blank.
  - `lexer.FOLD_HEADER`
    The line is a header, or fold point.

<a id="lexer.get_rule"></a>
### `lexer.get_rule`(*lexer*, *id*)

Returns a lexer's rule.

Parameters:
- *lexer*:  Lexer to fetch a rule from.
- *id*:  String id of the rule to fetch.

<a id="lexer.graph"></a>
### `lexer.graph`

A pattern that matches any graphical character ('!' to '~').

<a id="lexer.hex_num"></a>
### `lexer.hex_num`

A pattern that matches a hexadecimal number.

<a id="lexer.hex_num_"></a>
### `lexer.hex_num_`(*c*)

Returns a pattern that matches a hexadecimal number, whose digits may be separated by
a particular character.

Parameters:
- *c*:  Digit separator character.

<a id="lexer.indent_amount"></a>
### `lexer.indent_amount`

Map of line numbers (starting from 1) to their indentation amounts, measured in character
columns.
(Read-only)

<a id="lexer.integer"></a>
### `lexer.integer`

A pattern that matches either a decimal, hexadecimal, octal, or binary number.

<a id="lexer.integer_"></a>
### `lexer.integer_`(*c*)

Returns a pattern that matches either a decimal, hexadecimal, octal, or binary number,
whose digits may be separated by a particular character.

Parameters:
- *c*:  Digit separator character.

<a id="lexer.lex"></a>
### `lexer.lex`(*lexer*, *text*, *init_style*)

Lexes a chunk of text.

Parameters:
- *lexer*:  Lexer to lex text with.
- *text*:  String text to lex, which may be a partial chunk, single line, or full text.
- *init_style*:  Number of the text's current style. Multiple-language lexers use this to
   determine which language to start lexing in.

Returns: table of tag names and positions.

Usage:

```lua
lex:lex(...) --> {'keyword', 2, 'whitespace.lua', 3, 'identifier', 7}
```

<a id="lexer.line_from_position"></a>
### `lexer.line_from_position`(*pos*)

Returns a position's line number (starting from 1).

Parameters:
- *pos*:  The position (starting from 1) to get the line number of.

<a id="lexer.line_state"></a>
### `lexer.line_state`

Map of line numbers (starting from 1) to their 32-bit integer line states.

Line states can be used by lexers for keeping track of persistent states (up to 32 states
with 1 state per bit). For example, the output lexer uses this to mark lines that have
warnings or errors.

<a id="lexer.load"></a>
### `lexer.load`(*name*[, *alt_name*])

Initializes or loads a lexer.

Scintilla calls this function in order to load a lexer. Parent lexers also call this function
in order to load child lexers and vice-versa. The user calls this function in order to load
a lexer when using Scintillua as a Lua library.

Parameters:
- *name*:  String name of the lexing language.
- *alt_name*:  String alternate name of the lexing language. This is useful for
   embedding the same child lexer with multiple sets of start and end tags.

Returns: lexer object

<a id="lexer.lower"></a>
### `lexer.lower`

A pattern that matches any lower case character ('a'-'z').

<a id="lexer.modify_rule"></a>
### `lexer.modify_rule`(*lexer*, *id*, *rule*)

Replaces a lexer's existing rule.

Parameters:
- *lexer*:  Lexer to modify.
- *id*:  String id of the rule to replace.
- *rule*:  LPeg pattern of the new rule.

<a id="lexer.names"></a>
### `lexer.names`([*path*])

Returns a table of all known lexer names.

This function is not available to lexers and requires the LuaFileSystem (`lfs`) module to
be available.

Parameters:
- *path*:  String list of ';'-separated directories to search for lexers in. The
   default value is Scintillua's configured lexer path.

<a id="lexer.new"></a>
### `lexer.new`(*name*[, *opts*])

Creates a new lexer.

Parameters:
- *name*:  String lexer name. Use `...` to inherit from the file's name.
- *opts*:  Table of lexer options. Options currently supported:
   - `lex_by_line`: Only processes whole lines of text at a time (instead of arbitrary chunks
     of text). Line lexers cannot look ahead to subsequent lines. The default value is `false`.
   - `fold_by_indentation`: Calculate fold points based on changes in line indentation. The
     default value is `false`.
   - `case_insensitive_fold_points`: Fold points added via [`lexer.add_fold_point()`](#lexer.add_fold_point) should
     ignore case. The default value is `false`.
   - `no_user_word_lists`: Do not automatically allocate word lists that can be set by
     users. This should really only be set by non-programming languages like markup languages.
   - `inherit`: Lexer to inherit from. The default value is `nil`.

Returns: lexer object

Usage:

```lua
lexer.new(..., {inherit = lexer.load('html')}) -- name is 'rhtml' in rhtml.lua file
```

<a id="lexer.newline"></a>
### `lexer.newline`

A pattern that matches an end of line, either CR+LF or LF.

<a id="lexer.nonnewline"></a>
### `lexer.nonnewline`

A pattern that matches any single, non-newline character.

<a id="lexer.number"></a>
### `lexer.number`

A pattern that matches a typical number, either a floating point, decimal, hexadecimal,
octal, or binary number.

<a id="lexer.number_"></a>
### `lexer.number_`(*c*)

Returns a pattern that matches a typical number, either a floating point, decimal, hexadecimal,
octal, or binary number, and whose digits may be separated by a particular character.

Parameters:
- *c*:  Digit separator character.

Usage:

```lua
lexer.number_('_') -- matches 1_000_000
```

<a id="lexer.oct_num"></a>
### `lexer.oct_num`

A pattern that matches an octal number.

<a id="lexer.oct_num_"></a>
### `lexer.oct_num_`(*c*)

Returns a pattern that matches an octal number, whose digits may be separated by a particular
character.

Parameters:
- *c*:  Digit separator character.

<a id="lexer.property"></a>
### `lexer.property`

Map of key-value string pairs.

The contents of this map are application-dependant.

<a id="lexer.property_int"></a>
### `lexer.property_int`

Alias of [`lexer.property`](#lexer.property), but with values interpreted as numbers, or `0` if not
found.
(Read-only)

<a id="lexer.punct"></a>
### `lexer.punct`

A pattern that matches any punctuation character ('!' to '/', ':' to '@', '[' to ''', '{'
to '~').

<a id="lexer.range"></a>
### `lexer.range`(*s*[, *e*=s[, *single_line*=false[, *escapes*[, *balanced*=false]]]])

Returns a pattern that matches a bounded range of text.

This is a convenience function for matching more complicated ranges like strings with escape
characters, balanced parentheses, and block comments (nested or not).

Parameters:
- *s*:  String or LPeg pattern start of the range.
- *e*:  String or LPeg pattern end of the range. The default value is *s*.
- *single_line*:  Restrict the range to a single line.
- *escapes*:  Allow the range end to be escaped by a '\\' character. The default
   value is `false` unless *s* and *e* are identical, single-character strings. In that case,
   the default value is `true`.
- *balanced*:  Match a balanced range, like the "%b" Lua pattern. This flag
   only applies if *s* and *e* are different.

Usage:

```lua
local dq_str_escapes = lexer.range('"')
local dq_str_noescapes = lexer.range('"', false, false)
local unbalanced_parens = lexer.range('(', ')')
local balanced_parens = lexer.range('(', ')', false, false, true)
```

<a id="lexer.set_word_list"></a>
### `lexer.set_word_list`(*lexer*, *name*, *word_list*[, *append*=false])

Sets the words in a lexer's word list.

This only has an effect if the lexer uses [`lexer.word_match()`](#lexer.word_match) to reference the given list.

Parameters:
- *lexer*:  Lexer to add a word list to.
- *name*:  String name or number of the word list to set.
- *word_list*:  Table of words or a string list of words separated by
   spaces. Case-insensitivity is specified by a [`lexer.word_match()`](#lexer.word_match) reference to this list.
- *append*:  Append *word_list* to an existing word list (if any).

<a id="lexer.space"></a>
### `lexer.space`

A pattern that matches any whitespace character ('\t', '\v', '\f', '\n', '\r', space).

<a id="lexer.starts_line"></a>
### `lexer.starts_line`(*patt*[, *allow_indent*=false])

Returns a pattern that matches only at the beginning of a line.

Parameters:
- *patt*:  LPeg pattern to match at the beginning of a line.
- *allow_indent*:  Allow *patt* to match after line indentation.

Usage:

```lua
local preproc = lex:tag(lexer.PREPROCESSOR, lexer.starts_line(lexer.to_eol('#')))
```

<a id="lexer.style_at"></a>
### `lexer.style_at`

Map of buffer positions (starting from 1) to their string style names.
(Read-only)

<a id="lexer.tag"></a>
### `lexer.tag`(*lexer*, *name*, *patt*)

Returns a tagged pattern.

Parameters:
- *lexer*:  Lexer to tag the pattern in.
- *name*:  String name to use for the tag. If it is not a predefined tag name
	(`lexer.[A-Z_]+`), its Scintilla style will likely need to be defined by the editor or
	theme using this lexer.
- *patt*:  LPeg pattern to tag.

Usage:

```lua
local number = lex:tag(lexer.NUMBER, lexer.number)
local addition = lex:tag('addition', '+' * lexer.word)
```

<a id="lexer.to_eol"></a>
### `lexer.to_eol`([*prefix*[, *escape*=false]])

Returns a pattern that matches a prefix until the end of its line.

Parameters:
- *prefix*:  String or pattern prefix to start matching at. The default value is any
   non-newline character.
- *escape*:  Allow newline escapes using a '\\' character.

Usage:

```lua
local line_comment = lexer.to_eol('//')
local line_comment = lexer.to_eol(S('#;'))
```

<a id="lexer.upper"></a>
### `lexer.upper`

A pattern that matches any upper case character ('A'-'Z').

<a id="lexer.word"></a>
### `lexer.word`

A pattern that matches a typical word.
Words begin with a letter or underscore and consist
of alphanumeric and underscore characters.

<a id="lexer.word_match"></a>
### `lexer.word_match`([*lexer*], *word_list*[, *case_insensitive*=false])

Returns a pattern that matches a word in a word list.

This is a convenience function for simplifying a set of ordered choice word patterns and
potentially allowing downstream users to configure word lists.

Parameters:
- *lexer*:  Lexer to match a word in a word list for. This parameter may be omitted
   for lexer-agnostic matching.
- *word_list*:  Either a string name of the word list to match from if *lexer* is given, or,
   if *lexer* is omitted, a table of words or a string list of words separated by spaces. If a
   word list name was given and there is ultimately no word list set via `lex:set_word_list()`,
   no error will be raised, but the returned pattern will not match anything.
- *case_insensitive*:  Match the word case-insensitively.

Usage:

```lua
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))
local keyword = lex:tag(lexer.KEYWORD, lexer.word_match{'foo', 'bar', 'baz'})
local keyword = lex:tag(lexer.KEYWORD, lexer.word_match({'foo-bar', 'foo-baz',
   'bar-foo', 'bar-baz', 'baz-foo', 'baz-bar'}, true))
local keyword = lex:tag(lexer.KEYWORD, lexer.word_match('foo bar baz'))
```

<a id="lexer.xdigit"></a>
### `lexer.xdigit`

A pattern that matches any hexadecimal digit ('0'-'9', 'A'-'F', 'a'-'f').



