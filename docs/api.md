## Scintillua API Documentation

<a id="lexer"></a>
## The `lexer` Lua Module
---

Lexes Scintilla documents and source code with Lua and LPeg.

### Writing Lua Lexers

Lexers recognize and tag elements of source code for syntax highlighting. Scintilla (the
editing component behind [Textadept][] and [SciTE][]) traditionally uses static, compiled C++
lexers which are notoriously difficult to create and/or extend. On the other hand, Lua makes
it easy to to rapidly create new lexers, extend existing ones, and embed lexers within one
another. Lua lexers tend to be more readable than C++ lexers too.

While lexers can be written in plain Lua, Scintillua prefers using Parsing Expression
Grammars, or PEGs, composed with the Lua [LPeg library][]. As a result, this document is
devoted to writing LPeg lexers. The following table comes from the LPeg documentation and
summarizes all you need to know about constructing basic LPeg patterns. This module provides
convenience functions for creating and working with other more advanced patterns and concepts.

Operator | Description
-|-
`lpeg.P(string)` | Matches `string` literally.
`lpeg.P(`_`n`_`)` | Matches exactly _`n`_ number of characters.
`lpeg.S(string)` | Matches any character in set `string`.
`lpeg.R("`_`xy`_`")`| Matches any character between range `x` and `y`.
`patt^`_`n`_ | Matches at least _`n`_ repetitions of `patt`.
`patt^-`_`n`_ | Matches at most _`n`_ repetitions of `patt`.
`patt1 * patt2` | Matches `patt1` followed by `patt2`.
`patt1 + patt2` | Matches `patt1` or `patt2` (ordered choice).
`patt1 - patt2` | Matches `patt1` if `patt2` does not also match.
`-patt` | Equivalent to `("" - patt)`.
`#patt` | Matches `patt` but consumes no input.

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
and modify that lexer, saving some time and effort. The filename of your lexer should be the
name of your programming language in lower case followed by a *.lua* extension. For example,
a new Lua lexer has the name *lua.lua*.

Note: Try to refrain from using one-character language names like "c", "d", or "r". For
example, Scintillua uses "ansi_c", "dmd", and "rstats", respectively.

#### New Lexer Template

There is a *lexers/template.txt* file that contains a simple template for a new lexer. Feel
free to use it, replacing the '?' with the name of your lexer. Consider this snippet from
the template:

    -- ? LPeg lexer.

    local lexer = lexer
    local P, S = lpeg.P, lpeg.S

    local lex = lexer.new(...)

    [... lexer rules ...]

    -- Identifier.
    local identifier = lex:tag(lexer.IDENTIFIER, lexer.word)
    lex:add_rule('identifier', identifier)

    [... more lexer rules ...]

    return lex

The first line of code is a Lua convention to store a global variable into a local variable
for quick access. The second line simply defines often used convenience variables. The third
and last lines [define](#lexer.new) and return the lexer object Scintilla uses; they are
very important and must be part of every lexer. Note the `...` passed to [`lexer.new()`](#lexer.new) is
literal: the lexer will assume the name of its filename or an alternative name specified by
[`lexer.load()`](#lexer.load) in embedded lexer applications. The fourth line uses something called a
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
tag name using the the [`lexer.tag()`](#lexer.tag) function. Let us examine the "identifier" tag used
in the template shown earlier:

    local identifier = lex:tag(lexer.IDENTIFIER, lexer.word)

At first glance, the first argument does not appear to be a string name and the second
argument does not appear to be an LPeg pattern. Perhaps you expected something like:

    lex:tag('identifier', (lpeg.R('AZ', 'az')  + '_') * (lpeg.R('AZ', 'az', '09') + '_')^0)

The `lexer` module actually provides a convenient list of common tag names and common LPeg
patterns for you to use. Tag names for programming languages include (but are not limited
to) [`lexer.DEFAULT`](#lexer.DEFAULT), [`lexer.COMMENT`](#lexer.COMMENT), [`lexer.STRING`](#lexer.STRING), [`lexer.NUMBER`](#lexer.NUMBER),
[`lexer.KEYWORD`](#lexer.KEYWORD), [`lexer.IDENTIFIER`](#lexer.IDENTIFIER), [`lexer.OPERATOR`](#lexer.OPERATOR), [`lexer.ERROR`](#lexer.ERROR),
[`lexer.PREPROCESSOR`](#lexer.PREPROCESSOR), [`lexer.CONSTANT`](#lexer.CONSTANT), [`lexer.CONSTANT_BUILTIN`](#lexer.CONSTANT_BUILTIN),
[`lexer.VARIABLE`](#lexer.VARIABLE), [`lexer.VARIABLE_BUILTIN`](#lexer.VARIABLE_BUILTIN), [`lexer.FUNCTION`](#lexer.FUNCTION),
[`lexer.FUNCTION_BUILTIN`](#lexer.FUNCTION_BUILTIN), [`lexer.FUNCTION_METHOD`](#lexer.FUNCTION_METHOD), [`lexer.CLASS`](#lexer.CLASS), [`lexer.TYPE`](#lexer.TYPE),
[`lexer.LABEL`](#lexer.LABEL), [`lexer.REGEX`](#lexer.REGEX), [`lexer.EMBEDDED`](#lexer.EMBEDDED), and [`lexer.ANNOTATION`](#lexer.ANNOTATION). Tag
names for markup languages include (but are not limited to) [`lexer.TAG`](#lexer.TAG),
[`lexer.ATTRIBUTE`](#lexer.ATTRIBUTE), [`lexer.HEADING`](#lexer.HEADING), [`lexer.BOLD`](#lexer.BOLD), [`lexer.ITALIC`](#lexer.ITALIC),
[`lexer.UNDERLINE`](#lexer.UNDERLINE), [`lexer.CODE`](#lexer.CODE), [`lexer.LINK`](#lexer.LINK), [`lexer.REFERENCE`](#lexer.REFERENCE), and
[`lexer.LIST`](#lexer.LIST). Patterns include [`lexer.any`](#lexer.any), [`lexer.alpha`](#lexer.alpha), [`lexer.digit`](#lexer.digit),
[`lexer.alnum`](#lexer.alnum), [`lexer.lower`](#lexer.lower), [`lexer.upper`](#lexer.upper), [`lexer.xdigit`](#lexer.xdigit), [`lexer.graph`](#lexer.graph),
[`lexer.print`](#lexer.print), [`lexer.punct`](#lexer.punct), [`lexer.space`](#lexer.space), [`lexer.newline`](#lexer.newline),
[`lexer.nonnewline`](#lexer.nonnewline), [`lexer.dec_num`](#lexer.dec_num), [`lexer.hex_num`](#lexer.hex_num), [`lexer.oct_num`](#lexer.oct_num),
[`lexer.bin_num`](#lexer.bin_num), [`lexer.integer`](#lexer.integer), [`lexer.float`](#lexer.float), [`lexer.number`](#lexer.number), and
[`lexer.word`](#lexer.word). You may use your own tag names if none of the above fit your language,
but an advantage to using predefined tag names is that the language elements your lexer
recognizes will inherit any universal syntax highlighting color theme that your editor
uses. You can also "subclass" existing tag names by appending a '.*subclass*' string to
them. For example, the HTML lexer tags unknown tags as `lexer.TAG .. '.unknown'`. Editors
have the ability to style those subclassed tags in a different way than normal tags, or fall
back to styling them as normal tags.

##### Example Tags

So, how might you recognize and tag elements like keywords, comments, and strings?  Here are
some examples.

**Keywords**

Instead of matching _n_ keywords with _n_ `P('keyword_`_`n`_`')` ordered choices, use one
of of the following methods:

1. Use the convenience function [`lexer.word_match()`](#lexer.word_match) optionally coupled with
  [`lexer.set_word_list()`](#lexer.set_word_list). It is much easier and more efficient to write word matches like:

      local keyword = lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD))
      [...]
      lex:set_word_list(lexer.KEYWORD, {
        'keyword_1', 'keyword_2', ..., 'keyword_n'
      })

      local case_insensitive_word = lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD, true))
      [...]
      lex:set_word_list(lexer.KEYWORD, {
        'KEYWORD_1', 'keyword_2', ..., 'KEYword_n'
      })

      local hyphenated_keyword = lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD))
      [...]
      lex:set_word_list(lexer.KEYWORD, {
        'keyword-1', 'keyword-2', ..., 'keyword-n'
      })

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

       local keyword = lex:tag(lexer.KEYWORD, lexer.word_match{
         'keyword_1', 'keyword_2', ..., 'keyword_n'
       })

       local case_insensitive_keyword = lex:tag(lexer.KEYWORD, lexer.word_match({
         'KEYWORD_1', 'keyword_2', ..., 'KEYword_n'
       }, true))

       local hyphened_keyword = lex:tag(lexer.KEYWORD, lexer.word_match{
         'keyword-1', 'keyword-2', ..., 'keyword-n'
       })

   For short keyword lists, you can use a single string of words. For example:

       local keyword = lex:tag(lexer.KEYWORD, lexer.word_match('key_1 key_2 ... key_n'))

   You can use this method for static word lists that do not change, or where it does not
   make sense to allow applications or other lexers to extend or replace a word list.

**Comments**

Line-style comments with a prefix character(s) are easy to express:

    local shell_comment = lex:tag(lexer.COMMENT, lexer.to_eol('#'))
    local c_line_comment = lex:tag(lexer.COMMENT, lexer.to_eol('//', true))

The comments above start with a '#' or "//" and go to the end of the line (EOL). The second
comment recognizes the next line also as a comment if the current line ends with a '\'
escape character.

C-style "block" comments with a start and end delimiter are also easy to express:

    local c_comment = lex:tag(lexer.COMMENT, lexer.range('/*', '*/'))

This comment starts with a "/\*" sequence and contains anything up to and including an ending
"\*/" sequence. The ending "\*/" is optional so the lexer can recognize unfinished comments
as comments and highlight them properly.

**Strings**

Most programming languages allow escape sequences in strings such that a sequence like
"\\&quot;" in a double-quoted string indicates that the '&quot;' is not the end of the
string. [`lexer.range()`](#lexer.range) handles escapes inherently.

    local dq_str = lexer.range('"')
    local sq_str = lexer.range("'")
    local string = lex:tag(lexer.STRING, dq_str + sq_str)

In this case, the lexer treats '\' as an escape character in a string sequence.

**Numbers**

Most programming languages have the same format for integer and float tokens, so it might
be as simple as using a predefined LPeg pattern:

    local number = lex:tag(lexer.NUMBER, lexer.number)

However, some languages allow postfix characters on integers.

    local integer = P('-')^-1 * (lexer.dec_num * S('lL')^-1)
    local number = lex:tag(lexer.NUMBER, lexer.float + lexer.hex_num + integer)

Your language may need other tweaks, but it is up to you how fine-grained you want your
highlighting to be. After all, you are not writing a compiler or interpreter!

#### Rules

Programming languages have grammars, which specify valid syntactic structure. For example,
comments usually cannot appear within a string, and valid identifiers (like variable names)
cannot be keywords. In Lua lexers, grammars consist of LPeg pattern rules, many of which
are tagged.  Recall from the lexer template the [`lexer.add_rule()`](#lexer.add_rule) call, which adds a
rule to the lexer's grammar:

    lex:add_rule('identifier', identifier)

Each rule has an associated name, but rule names are completely arbitrary and serve only to
identify and distinguish between different rules. Rule order is important: if text does not
match the first rule added to the grammar, the lexer tries to match the second rule added, and
so on. Right now this lexer simply matches identifier tokens under a rule named "identifier".

To illustrate the importance of rule order, here is an example of a simplified Lua lexer:

    lex:add_rule('keyword', lex:tag(lexer.KEYWORD, ...))
    lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, ...))
    lex:add_rule('string', lex:tag(lexer.STRING, ...))
    lex:add_rule('comment', lex:tag(lexer.COMMENT, ...))
    lex:add_rule('number', lex:tag(lexer.NUMBER, ...))
    lex:add_rule('label', lex:tag(lexer.LABEL, ...))
    lex:add_rule('operator', lex:tag(lexer.OPERATOR, ...))

Notice how identifiers come _after_ keywords. In Lua, as with most programming languages,
the characters allowed in keywords and identifiers are in the same set (alphanumerics
plus underscores). If the lexer added the "identifier" rule before the "keyword" rule,
all keywords would match identifiers and thus would be incorrectly tagged (and likewise
incorrectly highlighted) as identifiers instead of keywords. The same idea applies to function,
constant, etc. tokens that you may want to distinguish between: their rules should come
before identifiers.

So what about text that does not match any rules? For example in Lua, the '!' character is
meaningless outside a string or comment. Normally the lexer skips over such text. If instead
you want to highlight these "syntax errors", add an additional end rule:

    lex:add_rule('keyword', keyword)
    ...
    lex:add_rule('error', lex:tag(lexer.ERROR, lexer.any))

This identifies and tags any character not matched by an existing rule as a `lexer.ERROR`.

Even though the rules defined in the examples above contain a single tagged pattern, rules may
consist of multiple tagged patterns. For example, the rule for an HTML tag could consist of a
tagged tag followed by an arbitrary number of tagged attributes, separated by whitespace. This
allows the lexer to produce all tags separately, but in a single, convenient rule. That rule
might look something like this:

    local ws = lex:get_rule('whitespace') -- predefined rule for all lexers
    lex:add_rule('tag', tag_start * (ws * attributes)^0 * tag_end^-1)

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
chunks may be a full document, only the visible part of a document, or even just portions
of lines. Some lexers need to match whole lines. For example, a lexer for the output of a
file "diff" needs to know if the line started with a '+' or '-' and then style the entire
line accordingly. To indicate that your lexer matches by line, create the lexer with an
extra parameter:

    local lex = lexer.new(..., {lex_by_line = true})

Now the input text for the lexer is a single line at a time. Keep in mind that line lexers
do not have the ability to look ahead to subsequent lines.

#### Embedded Lexers

Scintillua lexers embed within one another very easily, requiring minimal effort. In the
following sections, the lexer being embedded is called the "child" lexer and the lexer a child
is being embedded in is called the "parent". For example, consider an HTML lexer and a CSS
lexer. Either lexer stands alone for styling their respective HTML and CSS files. However, CSS
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

    local css = lexer.load('css')

The next part of the embedding process is telling the parent lexer when to switch over
to the child lexer and when to switch back. The lexer refers to these indications as the
"start rule" and "end rule", respectively, and are just LPeg patterns. Continuing with the
HTML/CSS example, the transition from HTML to CSS is when the lexer encounters a "style"
tag with a "type" attribute whose value is "text/css":

    local css_tag = P('<style') * P(function(input, index)
      if input:find('^[^>]+type="text/css"', index) then return index end
    end)

This pattern looks for the beginning of a "style" tag and searches its attribute list for
the text "`type="text/css"`". (In this simplified example, the Lua pattern does not consider
whitespace between the '=' nor does it consider that using single quotes is valid.) If there
is a match, the functional pattern returns a value instead of `nil`. In this case, the value
returned does not matter because we ultimately want to style the "style" tag as an HTML tag,
so the actual start rule looks like this:

    local css_start_rule = #css_tag * tag

Now that the parent knows when to switch to the child, it needs to know when to switch
back. In the case of HTML/CSS, the switch back occurs when the lexer encounters an ending
"style" tag, though the lexer should still style the tag as an HTML tag:

    local css_end_rule = #P('</style>') * tag

Once the parent loads the child lexer and defines the child's start and end rules, it embeds
the child with the [`lexer.embed()`](#lexer.embed) function:

    lex:embed(css, css_start_rule, css_end_rule)

##### Child Lexer

The process for instructing a child lexer to embed itself into a parent is very similar to
embedding a child into a parent: first, load the parent lexer into the child lexer with the
[`lexer.load()`](#lexer.load) function and then create start and end rules for the child lexer. However,
in this case, call [`lexer.embed()`](#lexer.embed) with switched arguments. For example, in the PHP lexer:

    local html = lexer.load('html')
    local php_start_rule = lex:tag('php_tag', '<?php ')
    local php_end_rule = lex:tag('php_tag', '?>')
    html:embed(lex, php_start_rule, php_end_rule)

Note that the use of a 'php_tag' tag will require the editor using the lexer to specify how
to highlight text with that tag. In order to avoid this, you could use the `lexer.PREPROCESSOR`
tag instead.

#### Lexers with Complex State

A vast majority of lexers are not stateful and can operate on any chunk of text in a
document. However, there may be rare cases where a lexer does need to keep track of some
sort of persistent state. Rather than using `lpeg.P` function patterns that set state
variables, it is recommended to make use of Scintilla's built-in, per-line state integers via
[`lexer.line_state`](#lexer.line_state). It was designed to accommodate up to 32 bit flags for tracking state.
[`lexer.line_from_position()`](#lexer.line_from_position) will return the line for any position given to an `lpeg.P`
function pattern. (Any positions derived from that position argument will also work.)

Writing stateful lexers is beyond the scope of this document.

### Code Folding

When reading source code, it is occasionally helpful to temporarily hide blocks of code like
functions, classes, comments, etc. This is the concept of "folding". In the Textadept and
SciTE editors for example, little indicators in the editor margins appear next to code that
can be folded at places called "fold points". When the user clicks an indicator, the editor
hides the code associated with the indicator until the user clicks the indicator again. The
lexer specifies these fold points and what code exactly to fold.

The fold points for most languages occur on keywords or character sequences. Examples of
fold keywords are "if" and "end" in Lua and examples of fold character sequences are '{',
'}', "/\*", and "\*/" in C for code block and comment delimiters, respectively. However,
these fold points cannot occur just anywhere. For example, lexers should not recognize fold
keywords that appear within strings or comments. The [`lexer.add_fold_point()`](#lexer.add_fold_point) function
allows you to conveniently define fold points with such granularity. For example, consider C:

    lex:add_fold_point(lexer.OPERATOR, '{', '}')
    lex:add_fold_point(lexer.COMMENT, '/*', '*/')

The first assignment states that any '{' or '}' that the lexer tagged as an `lexer.OPERATOR`
is a fold point. Likewise, the second assignment states that any "/\*" or "\*/" that the
lexer tagged as part of a `lexer.COMMENT` is a fold point. The lexer does not consider any
occurrences of these characters outside their tagged elements (such as in a string) as fold
points. How do you specify fold keywords? Here is an example for Lua:

    lex:add_fold_point(lexer.KEYWORD, 'if', 'end')
    lex:add_fold_point(lexer.KEYWORD, 'do', 'end')
    lex:add_fold_point(lexer.KEYWORD, 'function', 'end')
    lex:add_fold_point(lexer.KEYWORD, 'repeat', 'until')

If your lexer has case-insensitive keywords as fold points, simply add a
`case_insensitive_fold_points = true` option to [`lexer.new()`](#lexer.new), and specify keywords in
lower case.

If your lexer needs to do some additional processing in order to determine if a tagged element
is a fold point, pass a function to `lex:add_fold_point()` that returns an integer. A return
value of `1` indicates the element is a beginning fold point and a return value of `-1`
indicates the element is an ending fold point. A return value of `0` indicates the element
is not a fold point. For example:

    local function fold_strange_element(text, pos, line, s, symbol)
      if ... then
        return 1 -- beginning fold point
      elseif ... then
        return -1 -- ending fold point
      end
      return 0
    end

    lex:add_fold_point('strange_element', '|', fold_strange_element)

Any time the lexer encounters a '|' that is tagged as a "strange_element", it calls the
`fold_strange_element` function to determine if '|' is a fold point. The lexer calls these
functions with the following arguments: the text to identify fold points in, the beginning
position of the current line in the text to fold, the current line's text, the position in
the current line the fold point text starts at, and the fold point text itself.

#### Fold by Indentation

Some languages have significant whitespace and/or no delimiters that indicate fold points. If
your lexer falls into this category and you would like to mark fold points based on changes
in indentation, create the lexer with a `fold_by_indentation = true` option:

    local lex = lexer.new(..., {fold_by_indentation = true})

### Using Lexers

**Textadept**

Place your lexer in your *~/.textadept/lexers/* directory so you do not overwrite it when
upgrading Textadept. Also, lexers in this directory override default lexers. Thus, Textadept
loads a user *lua* lexer instead of the default *lua* lexer. This is convenient for tweaking
a default lexer to your liking. Then add a [file type](#textadept.file_types) for your lexer
if necessary.

**SciTE**

Create a *.properties* file for your lexer and `import` it in either your *SciTEUser.properties*
or *SciTEGlobal.properties*. The contents of the *.properties* file should contain:

    file.patterns.[lexer_name]=[file_patterns]
    lexer.$(file.patterns.[lexer_name])=scintillua.[lexer_name]

where `[lexer_name]` is the name of your lexer (minus the *.lua* extension) and
`[file_patterns]` is a set of file extensions to use your lexer for.

SciTE assigns styles to tag names in order to perform syntax highlighting. Since the set of
tag names used for a given language changes, your *.properties* file should specify styles
for tag names instead of style numbers. For example:

    scintillua.styles.default=fore:#000000,back:#FFFFFF
    scintillua.styles.keyword=fore:#00007F,bold
    scintillua.styles.string=fore:#7F007F
    scintillua.styles.my_tag=

### Migrating Legacy Lexers

Legacy lexers are of the form:

    local lexer = require('lexer')
    local token, word_match = lexer.token, lexer.word_match
    local P, S = lpeg.P, lpeg.S

    local lex = lexer.new('?')

    -- Whitespace.
    lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

    -- Keywords.
    lex:add_rule('keyword', token(lexer.KEYWORD, word_match{
      [...]
    }))

    [... other rule definitions ...]

    -- Custom.
    lex:add_rule('custom_rule', token('custom_token', ...))
    lex:add_style('custom_token', lexer.styles.keyword .. {bold = true})

    -- Fold points.
    lex:add_fold_point(lexer.OPERATOR, '{', '}')

    return lex

While Scintillua will mostly handle such legacy lexers just fine without any changes, it is
recommended that you migrate yours. The migration process is fairly straightforward:

1. `lexer` exists in the default lexer environment, so `require('lexer')` should be replaced
   by simply `lexer`. (Keep in mind `local lexer = lexer` is a Lua idiom.)
2. Every lexer created using [`lexer.new()`](#lexer.new) should no longer specify a lexer name by
   string, but should instead use `...` (three dots), which evaluates to the lexer's filename
   or alternative name in embedded lexer applications.
3. Every lexer created using `lexer.new()` now includes a rule to match whitespace. Unless
   your lexer has significant whitespace, you can remove your legacy lexer's whitespace
   token and rule. Otherwise, your defined whitespace rule will replace the default one.
4. The concept of tokens has been replaced with tags. Instead of calling a `token()` function,
   call [`lex:tag()`](#lexer.tag) instead.
5. Lexers now support replaceable word lists. Instead of calling [`lexer.word_match()`](#lexer.word_match)
   with large word lists, call it as an instance method with an identifier string (typically
   something like `lexer.KEYWORD`). Then at the end of the lexer (before `return lex`), call
   [`lex:set_word_list()`](#lexer.set_word_list) with the same identifier and the usual
   list of words to match. This allows users of your lexer to call `lex:set_word_list()`
   with their own set of words should they wish to.
6. Lexers no longer specify styling information. Remove any calls to `lex:add_style()`.
7. `lexer.last_char_includes()` has been deprecated in favor of the new [`lexer.after_set()`](#lexer.after_set).
   Use the character set and pattern as arguments to that new function.

As an example, consider the following sample legacy lexer:

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

Following the migration steps would yield:

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

### Considerations

#### Performance

There might be some slight overhead when initializing a lexer, but loading a file from disk
into Scintilla is usually more expensive. Actually painting the syntax highlighted text to
the screen is often more expensive than the lexing operation. On modern computer systems,
I see no difference in speed between Lua lexers and Scintilla's C++ ones. Optimize lexers for
speed by re-arranging `lexer.add_rule()` calls so that the most common rules match first. Do
keep in mind that order matters for similar rules.

In some cases, folding may be far more expensive than lexing, particularly in lexers with a
lot of potential fold points. If your lexer is exhibiting signs of slowness, try disabling
folding in your text editor first. If that speeds things up, you can try reducing the number
of fold points you added, overriding `lexer.fold()` with your own implementation, or simply
eliminating folding support from your lexer.

#### Limitations

Embedded preprocessor languages like PHP cannot completely embed themselves into their parent
languages because the parent's tagged patterns do not support start and end rules. This
mostly goes unnoticed, but code like

    <div id="<?php echo $id; ?>">

will not style correctly. Also, these types of languages cannot currently embed themselves
into their parent's child languages either.

A language cannot embed itself into something like an interpolated string because it is
possible that if lexing starts within the embedded entity, it will not be detected as such,
so a child to parent transition cannot happen. For example, the following Ruby code will
not style correctly:

    sum = "1 + 2 = #{1 + 2}"

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

### Fields defined by `lexer`

<a id="lexer.ANNOTATION"></a>
#### `lexer.ANNOTATION` (string)

The tag name for annotation elements.

<a id="lexer.ATTRIBUTE"></a>
#### `lexer.ATTRIBUTE` (string)

The tag name for function attribute elements, typically in markup.

<a id="lexer.BOLD"></a>
#### `lexer.BOLD` (string)

The tag name for bold elements, typically in markup.

<a id="lexer.CLASS"></a>
#### `lexer.CLASS` (string)

The tag name for class elements.

<a id="lexer.CODE"></a>
#### `lexer.CODE` (string)

The tag name for code elements, typically in markup.

<a id="lexer.COMMENT"></a>
#### `lexer.COMMENT` (string)

The tag name for comment elements.

<a id="lexer.CONSTANT"></a>
#### `lexer.CONSTANT` (string)

The tag name for constant elements.

<a id="lexer.CONSTANT_BUILTIN"></a>
#### `lexer.CONSTANT_BUILTIN` (string)

The tag name for builtin constant elements.

<a id="lexer.DEFAULT"></a>
#### `lexer.DEFAULT` (string)

The tag name for default elements.

<a id="lexer.EMBEDDED"></a>
#### `lexer.EMBEDDED` (string)

The tag name for embedded elements.

<a id="lexer.ERROR"></a>
#### `lexer.ERROR` (string)

The tag name for error elements.

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

The tag name for function elements.

<a id="lexer.FUNCTION_BUILTIN"></a>
#### `lexer.FUNCTION_BUILTIN` (string)

The tag name for builtin function elements.

<a id="lexer.FUNCTION_METHOD"></a>
#### `lexer.FUNCTION_METHOD` (string)

The tag name for function method elements.

<a id="lexer.HEADING"></a>
#### `lexer.HEADING` (string)

The tag name for heading elements, typically in markup.

<a id="lexer.IDENTIFIER"></a>
#### `lexer.IDENTIFIER` (string)

The tag name for identifier elements.

<a id="lexer.ITALIC"></a>
#### `lexer.ITALIC` (string)

The tag name for builtin italic elements, typically in markup.

<a id="lexer.KEYWORD"></a>
#### `lexer.KEYWORD` (string)

The tag name for keyword elements.

<a id="lexer.LABEL"></a>
#### `lexer.LABEL` (string)

The tag name for label elements.

<a id="lexer.LINK"></a>
#### `lexer.LINK` (string)

The tag name for link elements, typically in markup.

<a id="lexer.LIST"></a>
#### `lexer.LIST` (string)

The tag name for list item elements, typically in markup.

<a id="lexer.NUMBER"></a>
#### `lexer.NUMBER` (string)

The tag name for number elements.

<a id="lexer.OPERATOR"></a>
#### `lexer.OPERATOR` (string)

The tag name for operator elements.

<a id="lexer.PREPROCESSOR"></a>
#### `lexer.PREPROCESSOR` (string)

The tag name for preprocessor elements.

<a id="lexer.REFERENCE"></a>
#### `lexer.REFERENCE` (string)

The tag name for reference elements, typically in markup.

<a id="lexer.REGEX"></a>
#### `lexer.REGEX` (string)

The tag name for regex elements.

<a id="lexer.STRING"></a>
#### `lexer.STRING` (string)

The tag name for string elements.

<a id="lexer.TAG"></a>
#### `lexer.TAG` (string)

The tag name for function tag elements, typically in markup.

<a id="lexer.TYPE"></a>
#### `lexer.TYPE` (string)

The tag name for type elements.

<a id="lexer.UNDERLINE"></a>
#### `lexer.UNDERLINE` (string)

The tag name for underlined elements, typically in markup.

<a id="lexer.VARIABLE"></a>
#### `lexer.VARIABLE` (string)

The tag name for variable elements.

<a id="lexer.VARIABLE_BUILTIN"></a>
#### `lexer.VARIABLE_BUILTIN` (string)

The tag name for builtin variable elements.

<a id="lexer.alnum"></a>
#### `lexer.alnum` (pattern)

A pattern that matches any alphanumeric character ('A'-'Z', 'a'-'z', '0'-'9').

<a id="lexer.alpha"></a>
#### `lexer.alpha` (pattern)

A pattern that matches any alphabetic character ('A'-'Z', 'a'-'z').

<a id="lexer.any"></a>
#### `lexer.any` (pattern)

A pattern that matches any single character.

<a id="lexer.bin_num"></a>
#### `lexer.bin_num` (pattern)

A pattern that matches a binary number.

<a id="lexer.dec_num"></a>
#### `lexer.dec_num` (pattern)

A pattern that matches a decimal number.

<a id="lexer.digit"></a>
#### `lexer.digit` (pattern)

A pattern that matches any digit ('0'-'9').

<a id="lexer.float"></a>
#### `lexer.float` (pattern)

A pattern that matches a floating point number.

<a id="lexer.fold_level"></a>
#### `lexer.fold_level` (table, Read-only)

Table of fold level bit-masks for line numbers starting from 1.
  Fold level masks are composed of an integer level combined with any of the following bits:

  * `lexer.FOLD_BASE`
    The initial fold level.
  * `lexer.FOLD_BLANK`
    The line is blank.
  * `lexer.FOLD_HEADER`
    The line is a header, or fold point.

<a id="lexer.graph"></a>
#### `lexer.graph` (pattern)

A pattern that matches any graphical character ('!' to '~').

<a id="lexer.hex_num"></a>
#### `lexer.hex_num` (pattern)

A pattern that matches a hexadecimal number.

<a id="lexer.indent_amount"></a>
#### `lexer.indent_amount` (table, Read-only)

Table of indentation amounts in character columns, for line numbers starting from 1.

<a id="lexer.integer"></a>
#### `lexer.integer` (pattern)

A pattern that matches either a decimal, hexadecimal, octal, or binary number.

<a id="lexer.line_state"></a>
#### `lexer.line_state` (table)

Table of integer line states for line numbers starting from 1.
  Line states can be used by lexers for keeping track of persistent states. For example,
  the output lexer uses this to mark lines that have warnings or errors.

<a id="lexer.lower"></a>
#### `lexer.lower` (pattern)

A pattern that matches any lower case character ('a'-'z').

<a id="lexer.newline"></a>
#### `lexer.newline` (pattern)

A pattern that matches a sequence of end of line characters.

<a id="lexer.nonnewline"></a>
#### `lexer.nonnewline` (pattern)

A pattern that matches any single, non-newline character.

<a id="lexer.num_user_word_lists"></a>
#### `lexer.num_user_word_lists` (number)

The number of word lists to add as rules to every lexer created by `lexer.new()`. These
  word lists are intended to be set by users outside the lexer. Each word in a list is tagged
  with the name `userlistN`, where N is the index of the list. The default value is `2`.

<a id="lexer.number"></a>
#### `lexer.number` (pattern)

A pattern that matches a typical number, either a floating point, decimal, hexadecimal,
  octal, or binary number.

<a id="lexer.oct_num"></a>
#### `lexer.oct_num` (pattern)

A pattern that matches an octal number.

<a id="lexer.property"></a>
#### `lexer.property` (table)

Map of key-value string pairs.

<a id="lexer.property_int"></a>
#### `lexer.property_int` (table, Read-only)

Map of key-value pairs with values interpreted as numbers, or `0` if not found.

<a id="lexer.punct"></a>
#### `lexer.punct` (pattern)

A pattern that matches any punctuation character ('!' to '/', ':' to '@', '[' to ''',
  '{' to '~').

<a id="lexer.space"></a>
#### `lexer.space` (pattern)

A pattern that matches any whitespace character ('\t', '\v', '\f', '\n', '\r', space).

<a id="lexer.style_at"></a>
#### `lexer.style_at` (table, Read-only)

Table of style names at positions in the buffer starting from 1.

<a id="lexer.upper"></a>
#### `lexer.upper` (pattern)

A pattern that matches any upper case character ('A'-'Z').

<a id="lexer.word"></a>
#### `lexer.word` (pattern)

A pattern that matches a typical word. Words begin with a letter or underscore and consist
  of alphanumeric and underscore characters.

<a id="lexer.xdigit"></a>
#### `lexer.xdigit` (pattern)

A pattern that matches any hexadecimal digit ('0'-'9', 'A'-'F', 'a'-'f').


### Functions defined by `lexer`

<a id="lexer.add_fold_point"></a>
#### `lexer.add_fold_point`(lexer, tag\_name, start\_symbol, end\_symbol)

Adds to lexer *lexer* a fold point whose beginning and end points are tagged with string
*tag_name* tags and have string content *start_symbol* and *end_symbol*, respectively.
In the event that *start_symbol* may or may not be a fold point depending on context, and that
additional processing is required, *end_symbol* may be a function that ultimately returns
`1` (indicating a beginning fold point), `-1` (indicating an ending fold point), or `0`
(indicating no fold point). That function is passed the following arguments:

  * `text`: The text being processed for fold points.
  * `pos`: The position in *text* of the beginning of the line currently being processed.
  * `line`: The text of the line currently being processed.
  * `s`: The position of *start_symbol* in *line*.
  * `symbol`: *start_symbol* itself.

Fields:

* `lexer`: The lexer to add a fold point to.
* `tag_name`: The tag name for text that indicates a fold point.
* `start_symbol`: The text that indicates the beginning of a fold point.
* `end_symbol`: Either the text that indicates the end of a fold point, or a function that
  returns whether or not *start_symbol* is a beginning fold point (1), an ending fold point
  (-1), or not a fold point at all (0).

Usage:

* `lex:add_fold_point(lexer.OPERATOR, '{', '}')`
* `lex:add_fold_point(lexer.KEYWORD, 'if', 'end')`
* `lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('#'))`
* `lex:add_fold_point('custom', function(text, pos, line, s, symbol) ... end)`

<a id="lexer.add_rule"></a>
#### `lexer.add_rule`(lexer, id, rule)

Adds pattern *rule* identified by string *id* to the ordered list of rules for lexer *lexer*.

Fields:

* `lexer`: The lexer to add the given rule to.
* `id`: The id associated with this rule. It does not have to be the same as the name
  passed to `tag()`.
* `rule`: The LPeg pattern of the rule.

See also:

* [`lexer.modify_rule`](#lexer.modify_rule)

<a id="lexer.after_set"></a>
#### `lexer.after_set`(set, patt, skip)

Creates and returns a pattern that matches pattern *patt* only when it comes after one of
the characters in string *set* (or when there are no characters behind *patt*), skipping
over any characters in string *skip*, which is whitespace by default.

Fields:

* `set`: String character set like one passed to `lpeg.S()`.
* `patt`: The LPeg pattern to match after a set character.
* `skip`: String character set to skip over. The default value is ' \t\r\n\v\f' (whitespace).

Usage:

* `local regex = lexer.after_set('+-*!%^&|=,([{', lexer.range('/'))`

<a id="lexer.bin_num_"></a>
#### `lexer.bin_num_`(c)

Returns a pattern that matches a binary number, whose digits may be separated by character *c*.

Fields:

* `c`: 

<a id="lexer.dec_num_"></a>
#### `lexer.dec_num_`(c)

Returns a pattern that matches a decimal number, whose digits may be separated by character *c*.

Fields:

* `c`: 

<a id="lexer.detect"></a>
#### `lexer.detect`(filename, line)

Returns the name of the lexer often associated with filename *filename* and/or content
line *line*.

Fields:

* `filename`: Optional string filename. The default value is read from the
  'lexer.scintillua.filename' property.
* `line`: Optional string first content line, such as a shebang line. The default value
  is read from the 'lexer.scintillua.line' property.

Return:

* string lexer name to pass to `load()`, or `nil` if none was detected

See also:

* [`lexer.detect_extensions`](#lexer.detect_extensions)
* [`lexer.detect_patterns`](#lexer.detect_patterns)
* [`lexer.load`](#lexer.load)

<a id="lexer.embed"></a>
#### `lexer.embed`(lexer, child, start\_rule, end\_rule)

Embeds child lexer *child* in parent lexer *lexer* using patterns *start_rule* and *end_rule*,
which signal the beginning and end of the embedded lexer, respectively.

Fields:

* `lexer`: The parent lexer.
* `child`: The child lexer.
* `start_rule`: The pattern that signals the beginning of the embedded lexer.
* `end_rule`: The pattern that signals the end of the embedded lexer.

Usage:

* `html:embed(css, css_start_rule, css_end_rule)`
* `html:embed(lex, php_start_rule, php_end_rule) -- from php lexer`

<a id="lexer.float_"></a>
#### `lexer.float_`(c)

Returns a pattern that matches a floating point number, whose digits may be separated by
character *c*.

Fields:

* `c`: 

<a id="lexer.fold"></a>
#### `lexer.fold`(lexer, text, start\_line, start\_level)

Determines fold points in a chunk of text *text* using lexer *lexer*, returning a table of
fold levels associated with line numbers.
*text* starts on line number *start_line* with a beginning fold level of *start_level*
in the buffer.

Fields:

* `lexer`: The lexer to fold text with.
* `text`: The text in the buffer to fold.
* `start_line`: The line number *text* starts on, counting from 1.
* `start_level`: The fold level *text* starts on.

Return:

* table of fold levels associated with line numbers.

<a id="lexer.fold_consecutive_lines"></a>
#### `lexer.fold_consecutive_lines`(prefix)

Returns for `lexer.add_fold_point()` the parameters needed to fold consecutive lines that
start with string *prefix*.

Fields:

* `prefix`: The prefix string (e.g. a line comment).

Usage:

* `lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('--'))`
* `lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('//'))`
* `lex:add_fold_point(lexer.KEYWORD, lexer.fold_consecutive_lines('import'))`

<a id="lexer.get_rule"></a>
#### `lexer.get_rule`(lexer, id)

Returns the rule identified by string *id*.

Fields:

* `lexer`: The lexer to fetch a rule from.
* `id`: The id of the rule to fetch.

Return:

* pattern

<a id="lexer.hex_num_"></a>
#### `lexer.hex_num_`(c)

Returns a pattern that matches a hexadecimal number, whose digits may be separated by
character *c*.

Fields:

* `c`: 

<a id="lexer.integer_"></a>
#### `lexer.integer_`(c)

Returns a pattern that matches either a decimal, hexadecimal, octal, or binary number,
whose digits may be separated by character *c*.

Fields:

* `c`: 

<a id="lexer.lex"></a>
#### `lexer.lex`(lexer, text, init\_style)

Lexes a chunk of text *text* (that has an initial style number of *init_style*) using lexer
*lexer*, returning a list of tag names and positions.

Fields:

* `lexer`: The lexer to lex text with.
* `text`: The text in the buffer to lex.
* `init_style`: The current style. Multiple-language lexers use this to determine which
  language to start lexing in.

Return:

* list of tag names and positions.

<a id="lexer.line_from_position"></a>
#### `lexer.line_from_position`(pos)

Returns the line number (starting from 1) of the line that contains position *pos*, which
starts from 1.

Fields:

* `pos`: The position to get the line number of.

Return:

* number

<a id="lexer.load"></a>
#### `lexer.load`(name, alt\_name)

Initializes or loads and then returns the lexer of string name *name*.
Scintilla calls this function in order to load a lexer. Parent lexers also call this function
in order to load child lexers and vice-versa. The user calls this function in order to load
a lexer when using Scintillua as a Lua library.

Fields:

* `name`: The name of the lexing language.
* `alt_name`: The alternate name of the lexing language. This is useful for embedding the
  same child lexer with multiple sets of start and end tags.

Return:

* lexer object

<a id="lexer.modify_rule"></a>
#### `lexer.modify_rule`(lexer, id, rule)

Replaces in lexer *lexer* the existing rule identified by string *id* with pattern *rule*.

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
  * `lex_by_line`: Whether or not the lexer only processes whole lines of text (instead of
    arbitrary chunks of text) at a time. Line lexers cannot look ahead to subsequent lines.
    The default value is `false`.
  * `fold_by_indentation`: Whether or not the lexer does not define any fold points and that
    fold points should be calculated based on changes in line indentation. The default value
    is `false`.
  * `case_insensitive_fold_points`: Whether or not fold points added via
    `lexer.add_fold_point()` ignore case. The default value is `false`.
  * `inherit`: Lexer to inherit from. The default value is `nil`.

Usage:

* `lexer.new('rhtml', {inherit = lexer.load('html')})`

<a id="lexer.number_"></a>
#### `lexer.number_`(c)

Returns a pattern that matches a typical number, either a floating point, decimal, hexadecimal,
octal, or binary number, and whose digits may be separated by character *c*.

Fields:

* `c`: 

<a id="lexer.oct_num_"></a>
#### `lexer.oct_num_`(c)

Returns a pattern that matches an octal number, whose digits may be separated by character *c*.

Fields:

* `c`: 

<a id="lexer.range"></a>
#### `lexer.range`(s, e, single\_line, escapes, balanced)

Creates and returns a pattern that matches a range of text bounded by strings or patterns *s*
and *e*.
This is a convenience function for matching more complicated ranges like strings with escape
characters, balanced parentheses, and block comments (nested or not). *e* is optional and
defaults to *s*. *single_line* indicates whether or not the range must be on a single line;
*escapes* indicates whether or not to allow '\' as an escape character; and *balanced*
indicates whether or not to handle balanced ranges like parentheses, and requires *s* and *e*
to be different.

Fields:

* `s`: String or pattern start of a range.
* `e`: Optional string or pattern end of a range. The default value is *s*.
* `single_line`: Optional flag indicating whether or not the range must be on a single
  line. The default value is `false`.
* `escapes`: Optional flag indicating whether or not the range end may be escaped by a '\'
  character. The default value is `false` unless *s* and *e* are identical, single-character
  strings. In that case, the default value is `true`.
* `balanced`: Optional flag indicating whether or not to match a balanced range, like the
  "%b" Lua pattern. This flag only applies if *s* and *e* are different.

Usage:

* `local dq_str_escapes = lexer.range('"')`
* `local dq_str_noescapes = lexer.range('"', false, false)`
* `local unbalanced_parens = lexer.range('(', ')')`
* `local balanced_parens = lexer.range('(', ')', false, false, true)`

Return:

* pattern

<a id="lexer.set_word_list"></a>
#### `lexer.set_word_list`(lexer, name, word\_list, append)

Sets in lexer *lexer* the word list identified by string or number *name* to string or
list *word_list*, appending to any existing word list if *append* is `true`.
This only has an effect if *lexer* uses `word_match()` to reference the given list.
Case-insensitivity is specified by `word_match()`.

Fields:

* `lexer`: The lexer to add the given word list to.
* `name`: The string name or number of the word list to set.
* `word_list`: A list of words or a string list of words separated by spaces.
* `append`: Whether or not to append *word_list* to the existing word list (if any). The
  default value is `false`.

See also:

* [`lexer.word_match`](#lexer.word_match)

<a id="lexer.starts_line"></a>
#### `lexer.starts_line`(patt, allow\_indent)

Creates and returns a pattern that matches pattern *patt* only at the beginning of a line,
or after any line indentation if *allow_indent* is `true`.

Fields:

* `patt`: The LPeg pattern to match on the beginning of a line.
* `allow_indent`: Whether or not to consider line indentation as the start of a line. The
  default value is `false`.

Usage:

* `local preproc = lex:tag(lexer.PREPROCESSOR, lexer.starts_line(lexer.to_eol('#')))`

Return:

* pattern

<a id="lexer.tag"></a>
#### `lexer.tag`(lexer, name, patt)

Creates and returns a pattern that tags pattern *patt* with name *name* in lexer *lexer*.
If *name* is not a predefined tag name, its Scintilla style will likely need to be defined
by the editor or theme using this lexer.

Fields:

* `lexer`: The lexer to tag the given pattern in.
* `name`: The name to use.
* `patt`: The LPeg pattern to tag.

Usage:

* `local number = lex:tag(lexer.NUMBER, lexer.number)`
* `local addition = lex:tag('addition', '+' * lexer.word)`

Return:

* pattern

<a id="lexer.to_eol"></a>
#### `lexer.to_eol`(prefix, escape)

Creates and returns a pattern that matches from string or pattern *prefix* until the end of
the line.
*escape* indicates whether the end of the line can be escaped with a '\' character.

Fields:

* `prefix`: Optional string or pattern prefix to start matching at. The default value is
  any non-newline character.
* `escape`: Optional flag indicating whether or not newlines can be escaped by a '\'
 character. The default value is `false`.

Usage:

* `local line_comment = lexer.to_eol('//')`
* `local line_comment = lexer.to_eol(S('#;'))`

Return:

* pattern

<a id="lexer.word_match"></a>
#### `lexer.word_match`(lexer, word\_list, case\_insensitive)

Either returns a pattern for lexer *lexer* (if given) that matches one word in the word list
identified by string *word_list*, ignoring case if *case_sensitive* is `true`, or, if *lexer*
is not given, creates and returns a pattern that matches any single word in list or string
*word_list*, ignoring case if *case_insensitive* is `true`.
This is a convenience function for simplifying a set of ordered choice word patterns and
potentially allowing downstream users to configure word lists.
If there is ultimately no word list set via `set_word_list()`, no error will be raised,
but the returned pattern will not match anything.

Fields:

* `lexer`: Optional lexer to match a word in a wordlist for. This parameter may be omitted
  for lexer-agnostic matching.
* `word_list`: Either a string name of the word list to match from if *lexer* is given,
  or, if *lexer* is omitted, a list of words or a string list of words separated by spaces.
* `case_insensitive`: Optional boolean flag indicating whether or not the word match is
  case-insensitive. The default value is `false`.

Usage:

* `lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))`
* `local keyword = lex:tag(lexer.KEYWORD, lexer.word_match{'foo', 'bar', 'baz'})`
* `local keyword = lex:tag(lexer.KEYWORD, lexer.word_match({'foo-bar', 'foo-baz',
  'bar-foo', 'bar-baz', 'baz-foo', 'baz-bar'}, true))`
* `local keyword = lex:tag(lexer.KEYWORD, lexer.word_match('foo bar baz'))`

Return:

* pattern

See also:

* [`lexer.set_word_list`](#lexer.set_word_list)


### Tables defined by `lexer`

<a id="lexer.detect_extensions"></a>
#### `lexer.detect_extensions`

Map of file extensions, without the '.' prefix, to their associated lexer names.
This map has precedence over Scintillua's built-in map.

See also:

* [`lexer.detect`](#lexer.detect)

<a id="lexer.detect_patterns"></a>
#### `lexer.detect_patterns`

Map of line patterns to their associated lexer names.
These are Lua string patterns, not LPeg patterns.
This map has precedence over Scintillua's built-in map.

See also:

* [`lexer.detect`](#lexer.detect)

---
