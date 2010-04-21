-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Performs lexing of Scintilla documents.
module('lexer', package.seeall)

-- Markdown:
-- ## Overview
--
-- Dynamic lexers are more flexible than Scintilla's static ones. They are often
-- more readable as well. This document provides all the information necessary
-- in order to write a new lexer. For illustrative purposes, a Lua lexer will be
-- created. Lexers are written using Parsing Expression Grammars or PEGs with
-- the Lua [LPeg library][LPeg]. Please familiarize yourself with LPeg's
-- documentation before proceeding.
--
-- [LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
--
-- ## Writing a Dynamic Lexer
--
-- Rather than writing a lexer from scratch, first see if your language is
-- similar to any of the 70+ languages supported. If so, you can copy and modify
-- that lexer, saving some time and effort.
--
-- #### Introduction
--
-- All lexers are contained in the `lexers/` directory. To begin, create a Lua
-- script with the name of your lexer and open it for editing.
--
--     $> cd lexers
--     $> textadept lua.lua
--
-- Inside the lexer, the heading should look like the following:
--
--     -- Lua LPeg lexer
--
--     local l = lexer
--     local token, word_match = l.token, l.word_match
--     local P, R, S, V = l.lpeg.P, l.lpeg.R, l.lpeg.S, l.lpeg.V
--
--     module(...)
--
-- Each lexer is a module so the global namespace is not cluttered with lexer
-- patterns and variables. The `...` is there for a reason! Do not replace it
-- with the name of your lexer. This is done by Lua automatically.
--
-- The local variables above the module give easy access to the many useful
-- functions available for creating lexers.
--
-- #### Lexer Language Structure
--
-- It is important to spend some time considering the structure of the language
-- you are creating the lexer for. What kinds of tokens does it have? Comments,
-- strings, keywords, etc.? Lua has 9 tokens: whitespace, comments, strings,
-- numbers, keywords, functions, constants, identifiers, and operators.
--
-- #### Tokens
--
-- In a lexer, tokens are comprised of a token type followed by an LPeg pattern.
-- They are created using the [`token()`](#token) function. A whitespace token
-- typically looks like:
--
--     local ws = token('whitespace', S('\t\v\f\n\r ')^1)
--
-- It is difficult to remember that a space character is either a `\t`, `\v`,
-- `\f`, `\n`, `\r`, or ` `. The `lexer` (`l`) module provides you with a
-- shortcut for this and many other character sequences. They are:
--
-- * `any`: Matches any single character.
-- * `ascii`: Matches any ASCII character (`0`..`127`).
-- * `extend`: Matches any ASCII extended character (`0`..`255`).
-- * `alpha`: Matches any alphabetic character (`A-Z`, `a-z`).
-- * `digit`: Matches any digit (`0-9`).
-- * `alnum`: Matches any alphanumeric character (`A-Z`, `a-z`, `0-9`).
-- * `lower`: Matches any lowercase character (`a-z`).
-- * `upper`: Matches any uppercase character (`A-Z`).
-- * `xdigit`: Matches any hexadecimal digit (`0-9`, `A-F`, `a-f`).
-- * `cntrl`: Matches any control character (`0`..`31`).
-- * `graph`: Matches any graphical character (`!` to `~`).
-- * `print`: Matches any printable character (space to `~`).
-- * `punct`: Matches any punctuation character not alphanumeric (`!` to `/`,
--   `:` to `@`, `[` to `'`, `{` to `~`).
-- * `space`: Matches any whitespace character (`\t`, `\v`, `\f`, `\n`, `\r`,
--   space).
-- * `newline`: Matches any newline characters.
-- * `nonnewline`: Matches any non-newline character.
-- * `nonnewline_esc`: Matches any non-newline character excluding newlines
--   escaped with `\\`.
-- * `dec_num`: Matches a decimal number.
-- * `hex_num`: Matches a hexadecimal number.
-- * `oct_num`: Matches an octal number.
-- * `integer`: Matches a decimal, hexadecimal, or octal number.
-- * `float`: Matches a floating point number.
-- * `word`: Matches a typical word starting with a letter or underscore and
--   then any alphanumeric or underscore characters.
--
-- The above whitespace token can be rewritten more simply as:
--
--     local ws = token('whitespace', l.space^1)
--
-- The next Lua token is a comment. Short comments beginning with `--` are easy
-- to express with LPeg:
--
--     local line_comment = '--' * l.nonnewline^0
--
-- On the other hand, long comments are more difficult to express because they
-- have levels. See the [Lua Reference Manual][lexical_conventions] for more
-- information. As a result, a functional pattern is necessary:
--
--     local longstring = #('[[' + ('[' * P('=')^0 * '[')) *
--       P(function(input, index)
--       local level = input:match('^%[(=*)%[', index)
--        if level then
--          local _, stop = input:find(']'..level..']', index, true)
--          return stop and stop + 1 or #input + 1
--         end
--       end)
--     local block_comment = '--' * longstring
--
-- The token for a comment is then:
--
--     local comment = token('comment', line_comment + block_comment)
--
-- [lexical_conventions]: http://www.lua.org/manual/5.1/manual.html#2.1
--
-- It is worth noting that while token names are arbitrary, you are encouraged
-- to use the ones listed in the [`tokens`](#tokens) table because a standard
-- color theme is applied to them. If you wish to create a unique token, no
-- problem. You can specify how it will be colored later on.
--
-- Lua strings should be easy to express because they are just characters
-- surrounded by `'` or `"` characters, right? Not quite. Lua strings contain
-- escape sequences (`\`*`char`*) so a `\'` sequence in a single-quoted string
-- does not indicate the end of a string and must be handled appropriately.
-- Fortunately, this is a common occurance in many programming languages, so a
-- convenient function is provided: [`delimited_range()`](#delimited_range).
--
--     local sq_str = l.delimited_range("'", '\\', true)
--     local dq_str = l.delimited_range('"', '\\', true)
--
-- Lua also has multi-line strings, but they have the same format as block
-- comments. All strings can all be combined into a token:
--
--     local string = token('string', sq_str + dq_str + longstring)
--
-- Numbers are easy in Lua using `lexer`'s predefined patterns.
--
--     local lua_integer = P('-')^-1 * (l.hex_num + l.dec_num)
--     local number = token('number', l.float + lua_integer)
--
-- Keep in mind that the predefined patterns may not be completely accurate for
-- your language, so you may have to create your own variants. In the above
-- case, Lua integers do not have octal sequences, so the `l.integer` pattern is
-- not used.
--
-- Depending on the number of keywords for a particular language, a simple
-- `P(keyword1) + P(keyword2) + ... + P(keywordN)` pattern can get quite large.
-- In fact, LPeg has a limit on pattern size. Also, if the keywords are not case
-- sensitive, additional complexity arises, so a better approach is necessary.
-- Once again, `lexer` has a shortcut function: [`word_match()`](#word_match).
--
--     local keyword = token('keyword', word_match {
--       'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for',
--       'function', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
--       'return', 'then', 'true', 'until', 'while'
--     })
--
-- If keywords were case-insensitive, an additional parameter would be specified
-- in the call to [`word_match()`](#word_match); no other action is needed.
--
-- Lua functions and constants are specified like keywords:
--
--     local func = token('function', word_match {
--       'assert', 'collectgarbage', 'dofile', 'error', 'getfenv',
--       'getmetatable', 'gcinfo', 'ipairs', 'loadfile', 'loadlib',
--       'loadstring', 'next', 'pairs', 'pcall', 'print', 'rawequal',
--       'rawget', 'rawset', 'require', 'setfenv', 'setmetatable',
--       'tonumber', 'tostring', 'type', 'unpack', 'xpcall'
--     })
--
--     local constant = token('constant', word_match {
--       '_G', '_VERSION', 'LUA_PATH', '_LOADED', '_REQUIREDNAME', '_ALERT',
--       '_ERRORMESSAGE', '_PROMPT'
--     })
--
-- Unlike most programming languages, Lua allows an additional range of
-- characters in its identifier names (variables, functions, modules, etc.) so
-- the usual `l.word` cannot be used. Instead, identifiers are represented by:
--
--     local word = (R('AZ', 'az', '\127\255') + '_') * (l.alnum + '_')^0
--     local identifier = token('identifier', word)
--
-- Finally, an operator character is one of the following:
--
--     local operator = token('operator', '~=' + S('+-*/%^#=<>;:,.{}[]()'))
--
-- #### Rules
--
-- Rules are just a combination of tokens. In Lua, all rules consist of a
-- single token, but other languages may have two or more tokens in a rule.
-- For example, an HTML tag consists of an element token followed by an
-- optional set of attribute tokens. This allows each part of the tag to be
-- colored distinctly.
--
-- The set of rules that comprises Lua is specified in a `_rules` table for the
-- lexer.
--
--     _rules = {
--       { 'whitespace', ws },
--       { 'keyword', keyword },
--       { 'function', func },
--       { 'constant', constant },
--       { 'identifier', identifier },
--       { 'string', string },
--       { 'comment', comment },
--       { 'number', number },
--       { 'operator', operator },
--       { 'any_char', l.any_char },
--     }
--
-- Each entry is a rule name and its associated pattern. Please note that the
-- names of the rules can be completely different than the names of the tokens
-- contained within them.
--
-- The order of the rules is important because of the nature of LPeg. LPeg tries
-- to apply the first rule to the current position in the text it is matching.
-- If there is a match, it colors that section appropriately and moves on. If
-- there is not a match, it tries the next rule, and so on. Suppose instead that
-- the `identifier` rule was before the `keyword` rule. It can be seen that all
-- keywords satisfy the requirements for being an identifier, so any keywords
-- would be incorrectly colored as identifiers. This is why `identifier` is
-- where it is in the `_rules` table.
--
-- You might be wondering what that `any_char` is doing at the bottom of
-- `_rules`. Its purpose is to match anything not accounted for in the above
-- rules. For example, suppose the `!` character is in the input text. It will
-- not be matched by any of the first 9 rules, so without `any_char`, the text
-- would not match at all, and no coloring would occur. `any_char` matches one
-- single character and moves on. It may be colored red (indicating a syntax
-- error) if desired because it is a token, not just a pattern.
--
-- #### Summary
--
-- The above method of defining tokens and rules is sufficient for a majority of
-- lexers. The `lexer` module provides many useful patterns and functions for
-- constructing a working lexer quickly and efficiently. In most cases, the
-- amount of knowledge of LPeg required to write a lexer is minimal.
--
-- As long as you used token names listed in [`tokens`](#tokens), you do not
-- have to specify any coloring (or styling) information in the lexer; it is
-- taken care of by the user's color theme.
--
-- The rest of this document is devoted to more complex lexer techniques.
--
-- #### Styling Tokens
--
-- The term for coloring text is styling. Just like with predefined LPeg
-- patterns in `lexer`, predefined styles are available.
--
-- * `style_nothing`: Typically used for whitespace.
-- * `style_char`: Typically used for character literals.
-- * `style_class`: Typically used for class definitions.
-- * `style_comment`: Typically used for code comments.
-- * `style_constant`: Typically used for constants.
-- * `style_definition`: Typically used for definitions.
-- * `style_error`: Typically used for erroneous syntax.
-- * `style_function`: Typically used for function definitions.
-- * `style_keyword`: Typically used for language keywords.
-- * `style_number`: Typically used for numbers.
-- * `style_operator`: Typically used for operators.
-- * `style_string`: Typically used for strings.
-- * `style_preproc`: Typically used for preprocessor statements.
-- * `style_tag`: Typically used for markup tags.
-- * `style_type`: Typically used for static types.
-- * `style_variable`: Typically used for variables.
-- * `style_embedded`: Typically used for embedded code.
-- * `style_identifier`: Typically used for identifier words.
--
-- Each style consists of a set of attributes:
--
-- * `font`: The style's font name.
-- * `size`: The style's font size.
-- * `bold`: Flag indicating whether or not the font is boldface.
-- * `italic`: Flag indicating whether or not the font is italic.
-- * `underline`: Flag indicating whether or not the font is underlined.
-- * `fore`: The color of the font face.
-- * `back`: The color of the font background.
-- * `eolfilled`: Flag indicating whether or not to color the end of the line.
-- * `characterset`: The character set of the font.
-- * `case`: The case of the font. 1 for upper case, 2 for lower case, 0 for
--   normal case.
-- * `visible`: Flag indicating whether or not the text is visible.
-- * `changable`: Flag indicating whether or not the text is read-only.
-- * `hotspot`: Flag indicating whether or not the style is clickable.
--
-- Styles are created with [`style()`](#style). For example:
--
--     -- style with default theme settings
--     local style_nothing = l.style { }
--
--     -- style with bold text with default theme font
--     local style_bold = l.style { bold = true }
--
--     -- style with bold italic text with default theme font
--     local style_bold_italic = l.style { bold = true, italic = true }
--
-- The `style_bold_italic` style can be rewritten in terms of `style_bold`:
--
--     local style_bold_italic = style_bold..{ italic = true }
--
-- In this way you can build on previously defined styles without having to
-- rewrite them. Note the previous style is left unchanged.
--
-- Style colors are different than the #rrggbb RGB notation you may be familiar
-- with. Instead, create a color using [`color()`](#color).
--
--     local red = l.color('FF', '00', '00')
--     local green = l.color('00', 'FF', '00')
--     local blue = l.color('00', '00', 'FF')
--
-- As you might have guessed, `lexer` has a set of default colors.
--
-- * `green`
-- * `blue`
-- * `red`
-- * `yellow`
-- * `teal`
-- * `white`
-- * `black`
-- * `grey`
-- * `purple`
-- * `orange`
--
-- It is recommended to use them to stay consistant with a user's color theme.
--
-- Finally, styles are assigned to tokens via a `_tokenstyles` table in the
-- lexer. Styles do not have to be assigned to standard tokens; it is done
-- automatically. You only have to assign styles for tokens you create. For
-- example:
--
--     local lua = token('lua', P('lua'))
--
--     -- ... other patterns and tokens ...
--
--     _tokenstyles = {
--       { 'lua', l.style_keyword },
--     }
--
-- Each entry is the token name the style is for and the style itself. The order
-- of styles in `_tokenstyles` does not matter.
--
-- For examples of how styles are created, please see the theme files in the
-- `lexers/themes/` folder.
--
-- #### Line Lexer
--
-- Sometimes it is advantageous to lex input text line by line rather than a
-- chunk at a time. This occurs particularly in diff, patch, or make files. Put
--
--     _LEXBYLINE = true
--
-- somewhere in your lexer in order to do this.
--
-- #### Embedded Lexers
--
-- A particular advantage that dynamic lexers have over static ones is that
-- lexers can be embedded within one another very easily, requiring minimal
-- effort. There are two kinds of embedded lexers: a parent lexer that embeds
-- other child lexers in it, and a child lexer that embeds itself within a
-- parent lexer.
--
-- #### Parent Lexer with Children
--
-- An example of this kind of lexer is HTML with embedded CSS and Javascript.
-- After creating the parent lexer, load the children lexers in it using
-- [`lexer.load()`](#load). For example:
--
--     local css = l.load('css')
--
-- There needs to be a transition from the parent HTML lexer to the child CSS
-- lexer. This is something of the form `<style type="text/css">`. Similarly,
-- the transition from child to parent is `</style>`.
--
--     local css_start_rule = #(P('<') * P('style') *
--       P(function(input, index)
--         if input:find('[^>]+type%s*=%s*(["\'])text/css%1') then
--           return index
--         end
--       end)) * tag
--     local css_end_rule = #(P('</') * P('style') * ws^0 * P('>')) * tag
--
-- where `tag` and `ws` have been previously defined in the HTML lexer. Recall
-- that an `any_char` rule matches anything not matched previously in a lexer.
-- This rule exists in the CSS lexer, but we want it to stop matching when it
-- encounters `</style>` (otherwise the rest of the input would be counted as
-- CSS) without modifying the lexer file itself. The solution is to edit the
-- `any_char` rule from within the `css.`[`_RULES`](#_RULES) table:
--
--     css._RULES['any_char'] = token('css_default', l.any - css_end_rule)
--
-- Now the CSS lexer can be embedded using [`embed_lexer()`](#embed_lexer):
--
--     l.embed_lexer(_M, css, css_start_rule, css_end_rule)
--
-- What is `_M`? It is the parent HTML lexer object, not the string `...` or
-- `'html'`. The lexer object is needed by [`embed_lexer()`](#embed_lexer).
--
-- The same procedure can be done for Javascript, but with there is a wrinkle:
-- the child to parent transition (`</script>`) starts with a `<`, which is an
-- operator in Javascript. Therefore the `operator` rule must be edited in
-- addition to `any_char`.
--
--     local js = l.load('javascript')
--
--     local js_start_rule = #(P('<') * P('script') *
--       P(function(input, index)
--         if input:find('[^>]+type%s*=%s*(["\'])text/javascript%1') then
--           return index
--         end
--       end)) * tag
--     local js_end_rule = #('</' * P('script') * ws^0 * '>') * tag
--     js._RULES['operator'] = token('operator', S('+-/*%^!=&|?:;.()[]{}>') +
--                                               '<' * -('/' * P('script')))
--     js._RULES['any_char'] = token('js_default', l.any - js_end_rule)
--     l.embed_lexer(_M, js, js_start_rule, js_end_rule)
--
-- Note the tokens `css_default` and `js_default` that were added. Since they
-- are not standard tokens, styles must be added for them. If `_tokenstyles` has
-- already been defined in the parent lexer, styles are added this way:
--
--     _tokenstyles[#_tokenstyles + 1] = { 'css_default', l.style_nothing }
--     _tokenstyles[#_tokenstyles + 1] = { 'js_default', l.style_nothing }
--
-- #### Child Lexer Within Parent
--
-- An example of this kind of lexer is PHP embedded in HTML. After creating the
-- child lexer, load the parent lexer. As an example:
--
--     local html = l.load('hypertext')
--
-- Since HTML should be the main lexer, (PHP is just a preprocessing language),
-- the following statement changes the main lexer from PHP to HTML:
--
--     _lexer = html
--
-- Like in the previous section, transitions from HTML to PHP and back are
-- specified:
--
--     local php_start_rule = token('php_tag', '<?' * ('php' * l.space)^-1)
--     local php_end_rule = token('php_tag', '?>')
--
-- And PHP is embedded as a preprocessing language:
--
--     l.embed_lexer(html, _M, php_start_rule, php_end_rule, true)
--
-- If PHP were not a preprocessing language, the lexer would be finished.
-- However, PHP can appear *anywhere* within an HTML document, so the HTML lexer
-- needs to have this indicated in its rules -- for example within strings.
-- First, it is necessary to obtain the PHP rule (`<?php ... ?>` sequence).
--
--     local php_rules = _M._EMBEDDEDRULES[html._NAME]
--     local php_rule = php_rules.start_rule * php_rules.token_rule^0 *
--                      php_rules.end_rule^-1
--
-- Now, string patterns with embedded PHP need to be created. The explanation on
-- how to do so is beyond the scope of this tutorial. Sufficed to say a shortcut
-- function [`delimited_range_with_embedded()`](#delimited_range_with_embedded)
-- is available:
--
--     local embedded_sq_str =
--       l.delimited_range_with_embedded("'", '\\', 'string', php_rule)
--     local embedded_dq_str =
--       l.delimited_range_with_embedded('"', '\\', 'string', php_rule)
--
-- The HTML `string` rule can now be modified:
--
--     html._RULES['string'] = embedded_sq_str + embedded_dq_str
--
-- This procedure should be repeated for other rules, but is not shown here. You
-- can look at `lexers/php.lua` for more information.
--
-- #### Code Folding (Optional)
--
-- It is sometimes convenient to "fold", or not show blocks of text. These
-- blocks can be functions, classes, comments, etc. A folder iterates over each
-- line of input text and assigns a fold level to it. Certain lines can be
-- specified as fold points that fold subsequent lines with a higher fold level.
--
-- In order to implement a folder, define the following function in your lexer:
--
--     function _fold(input, start_pos, start_line, start_level)
--
--     end
--
-- * `input`: The text to fold.
-- * `start_pos`: Current position in the buffer of the text (used for obtaining
--   style information from the document).
-- * `start_line`: The line number the text starts at.
-- * `start_level`: The fold level of the text at `start_line`.
--
-- The function must return a table whose indices are line numbers and whose
-- values are tables containing the fold level and optionally a fold flag.
--
-- The following Scintilla fold flags are available:
--
-- * `SC_FOLDLEVELBASE`: The initial (root) fold level.
-- * `SC_FOLDLEVELWHITEFLAG`: Flag indicating that the line is blank.
-- * `SC_FOLDLEVELHEADERFLAG`: Flag indicating the line is fold point.
-- * `SC_FOLDLEVELNUMBERMASK`: Flag used with `SCI_GETFOLDLEVEL(line)` to get
--   the fold level of a line.
--
-- Have your fold function interate over each line, setting fold levels. You can
-- use the [`get_style_at()`](#get_style_at), [`get_property()`](#get_property),
-- [`get_fold_level()`](#get_fold_level), and
-- [`get_indent_amount()`](#get_indent_amount) functions as necessary to determine
-- the fold level for each line. The following example sets fold points by
-- changes in indentation.
--
--     function _fold(input, start_pos, start_line, start_level)
--       local folds = {}
--       local current_line = start_line
--       local prev_level = start_level
--       for indent, line in text:gmatch('([\t ]*)(.-)\r?\n') do
--         if #line > 0 then
--           local current_level = l.get_indent_amount(current_line)
--           if current_level > prev_level then -- next level
--             local i = current_line - 1
--             while folds[i] and folds[i][2] == l.SC_FOLDLEVELWHITEFLAG do
--               i = i - 1
--             end
--             if folds[i] then
--               folds[i][2] = l.SC_FOLDLEVELHEADERFLAG -- low indent
--             end
--             folds[current_line] = { current_level } -- high indent
--           elseif current_level < prev_level then -- prev level
--             if folds[current_line - 1] then
--               folds[current_line - 1][1] = prev_level -- high indent
--             end
--             folds[current_line] = { current_level } -- low indent
--           else -- same level
--             folds[current_line] = { prev_level }
--           end
--           prev_level = current_level
--         else
--           folds[current_line] = { prev_level, l.SC_FOLDLEVELWHITEFLAG }
--         end
--         current_line = current_line + 1
--       end
--       return folds
--     end
--
-- SciTE users note: do not use `get_property` for getting fold options from a
-- `.properties` file because SciTE is not set up to forward them to your lexer.
-- Instead, you can provide options that can be set at the top of the lexer.
--
-- #### Using the Lexer with SciTE
--
-- Create a `.properties` file for your lexer and `import` it in either your
-- `SciTEUser.properties` or `SciTEGlobal.properties`. The contents of the
-- `.properties` file should contain:
--
--     file.patterns.[lexer_name]=[file_patterns]
--     lexer.$(file.patterns.[lexer_name])=[lexer_name]
--
-- where [lexer\_name] is the name of your lexer (minus the `.lua` extension)
-- and [file\_patterns] is a set of file extensions matched to your lexer.
--
-- Please note any styling information in `.properties` files is ignored.
--
-- #### Using the Lexer with Textadept
--
-- Put your lexer in your [`~/.textadept/`][user]`lexers/` directory. That way
-- your lexer will not be overwritten when upgrading. Also, lexers in this
-- directory override default lexers. (A user `lua` lexer would be loaded
-- instead of the default `lua` lexer. This is convenient if you wish to tweak
-- a default lexer to your liking.) Do not forget to add a
-- [mime-type](textadept.mime_types.html) for your lexer.
--
-- [user]: http://caladbolg.net/luadoc/textadept2/manual/5_FolderStructure.html
--
-- #### Optimization
--
-- Lexers can usually be optimized for speed by re-arranging tokens so that the
-- most common ones are recognized first. Keep in mind the issue that was raised
-- earlier: if you put similar tokens like `identifier`s before `keyword`s, the
-- latter will not be styled correctly.
--
-- #### Troubleshooting
--
-- Errors in lexers can be tricky to debug. Lua errors and `_G.print()`
-- statements in lexers are printed to STDOUT.
--
-- #### Limitations
--
-- Lexers can have up to 32757 elements in them. So unless the lexer is written
-- very poorly, or has a dozen embedded languages, this limitation is not a
-- problem.
--
-- #### Performance
--
-- There might be some slight overhead when initializing a lexer, but loading a
-- file from disk into Scintilla is usually more expensive.
--
-- On modern computer systems, I see no difference in speed between LPeg lexers
-- and Scintilla's C++ ones for single language lexers. There may be differences
-- for multiple language lexers though, depending on the size of the file since
-- the entire document must be lexed to ensure accuracy.
--
-- #### Risks
--
-- Poorly written lexers have the ability to crash Scintilla, so unsaved data
-- might be lost. However, these crashes have only been observed in early lexer
-- development, when syntax errors or pattern errors are present. Once the lexer
-- actually starts styling text (either correctly or incorrectly; it does not
-- matter), no crashes have occurred.
--
-- #### Acknowledgements
--
-- Thanks to Peter Odding for his [lexer post][post] on the Lua mailing list
-- that inspired me, and of course thanks to Roberto Ierusalimschy for LPeg.
--
-- [post]: http://lua-users.org/lists/lua-l/2007-04/msg00116.html

local lpeg = require 'lpeg'

package.path = _LEXERHOME..'/?.lua'

---
-- [Local function] Adds a rule to a lexer's current ordered list of rules.
-- @param lexer The lexer to add the given rule to.
-- @param name The name associated with this rule. It is used for other lexers
--   to access this particular rule from the lexer's `_RULES` table. It does not
--   have to be the same as the name passed to `token`.
-- @param rule The LPeg pattern of the rule.
local function add_rule(lexer, id, rule)
  if not lexer._RULES then
---
-- List of rule names with associated LPeg patterns for a specific lexer.
-- It is accessible to other lexers for embedded lexer applications.
-- @class table
-- @name _RULES
    lexer._RULES = {}
    -- Contains an ordered list (by numerical index) of rule names. This is used
    -- in conjunction with lexer._RULES for building _TOKENRULE.
    lexer._RULEORDER = {}
  end
  lexer._RULES[id] = rule
  lexer._RULEORDER[#lexer._RULEORDER + 1] = id
end

---
-- [Local function] Adds a new Scintilla style to Scintilla.
-- @param lexer The lexer to add the given style to.
-- @param token_name The name of the token associated with this style.
-- @param style A Scintilla style created from style().
-- @see style
local function add_style(lexer, token_name, style)
  local len = lexer._STYLES.len
  if len == 32 then len = len + 8 end -- skip predefined styles
  if len >= 128 then _G.print('Too many styles defined (128 MAX)') end
  lexer._TOKENS[token_name] = len
  lexer._STYLES[len] = style
  lexer._STYLES.len = len + 1
end

---
-- [Local function] (Re)constructs lexer._TOKENRULE.
-- @param parent The parent lexer.
local function join_tokens(lexer)
  local patterns, order = lexer._RULES, lexer._RULEORDER
  local token_rule = patterns[order[1]]
  for i = 2, #order do token_rule = token_rule + patterns[order[i]] end
  lexer._TOKENRULE = token_rule
  return lexer._TOKENRULE
end

---
-- [Local function] (Re)constructs lexer._GRAMMAR.
-- @param lexer The parent lexer.
local function build_grammar(lexer)
  local token_rule = join_tokens(lexer)
  local children = lexer._CHILDREN
  if children then
    if #children.preproc > 0 then
      for _, preproc in ipairs(children.preproc) do
        local rules = preproc._EMBEDDEDRULES[lexer._NAME]
        local rule = rules.start_rule * rules.token_rule^0 * rules.end_rule^-1
        -- Add preproc's tokens before tokens of all other embedded languages.
        for _, child in ipairs(children) do
          if child ~= preproc then
            local rules = child._EMBEDDEDRULES[lexer._NAME]
            token_rule = rules.start_rule * (rule + rules.token_rule)^0 *
              rules.end_rule^-1 + token_rule
          end
        end
        token_rule = rule + token_rule
      end
    else
      for _, child in ipairs(children) do
        local rules = child._EMBEDDEDRULES[lexer._NAME]
        token_rule = rules.start_rule * rules.token_rule^0 * rules.end_rule^-1 +
          token_rule
      end
    end
  end
  lexer._GRAMMAR = lpeg.Ct(token_rule^0)
end

---
-- [Local table] Default tokens.
-- Contains token identifiers and associated style numbers.
-- @class table
-- @name tokens
-- @field default The default type (0).
-- @field whitespace The whitespace type (1).
-- @field comment The comment type (2).
-- @field string The string type (3).
-- @field number The number type (4).
-- @field keyword The keyword type (5).
-- @field identifier The identifier type (6).
-- @field operator The operator type (7).
-- @field error The error type (8).
-- @field preprocessor The preprocessor type (9).
-- @field constant The constant type (10).
-- @field function The function type (11).
-- @field class The class type (12).
-- @field type The type type (13).
local tokens = {
  default      = 0,
  whitespace   = 1,
  comment      = 2,
  string       = 3,
  number       = 4,
  keyword      = 5,
  identifier   = 6,
  operator     = 7,
  error        = 8,
  preprocessor = 9,
  constant     = 10,
  variable     = 11,
  ['function'] = 12,
  class        = 13,
  type         = 14,
}

---
-- Initializes the specified lexer.
-- @param lexer_name The name of the lexing language.
function load(lexer_name)
  local lexer = require(lexer_name or 'null')
  if not lexer then error('Lexer '..lexer_name..' does not exist') end
  lexer._TOKENS = tokens
  lexer._STYLES = {
    [0] = style_nothing,
    [1] = style_whitespace,
    [2] = style_comment,
    [3] = style_string,
    [4] = style_number,
    [5] = style_keyword,
    [6] = style_identifier,
    [7] = style_operator,
    [8] = style_error,
    [9] = style_preproc,
    [10] = style_constant,
    [11] = style_variable,
    [12] = style_function,
    [13] = style_class,
    [14] = style_type,
    len = 15,
    -- Predefined styles.
    [32] = style_default,
    [33] = style_line_number,
    [34] = style_bracelight,
    [35] = style_bracebad,
    [36] = style_controlchar,
    [37] = style_indentguide,
    [38] = style_calltip,
  }
  if lexer._lexer then
    local l, _r, _s = lexer._lexer, lexer._rules, lexer._tokenstyles
    for _, r in ipairs(_r or {}) do l._rules[#l._rules + 1] = r end
    for _, s in ipairs(_s or {}) do l._tokenstyles[#l._tokenstyles + 1] = s end
    lexer = l
  end
  if lexer._rules then
    for _, s in ipairs(lexer._tokenstyles or {}) do
      add_style(lexer, s[1], s[2])
    end
    for _, r in ipairs(lexer._rules) do add_rule(lexer, r[1], r[2]) end
    build_grammar(lexer)
  end
  _G._LEXER = lexer
  return lexer
end

---
-- Lexes the given text.
-- Called by LexLPeg.cxx; do not call from Lua.
-- If the lexer has a _LEXBYLINE flag set, the text is lexed one line at a time.
-- Otherwise the text is lexed as a whole.
-- @param text The text to lex.
function lex(text)
  local lexer = _G._LEXER
  if not lexer._GRAMMAR then return {} end
  if not lexer._LEXBYLINE then
    return lpeg.match(lexer._GRAMMAR, text)
  else
    local tokens = {}
    local function append(tokens, line_tokens, offset)
      for _, token in ipairs(line_tokens) do
        token[2] = token[2] + offset
        tokens[#tokens + 1] = token
      end
    end
    local offset = 0
    local grammar = lexer._GRAMMAR
    for line in text:gmatch('[^\r\n]*[\r\n]*') do
      local line_tokens = lpeg.match(grammar, line)
      if line_tokens then append(tokens, line_tokens, offset) end
      offset = offset + #line
      -- Use the default style to the end of the line if none was specified.
      if tokens[#tokens][2] ~= offset then
        tokens[#tokens + 1] = { 'default', offset + 1 }
      end
    end
    return tokens
  end
end

---
-- Folds the given text.
-- Called by LexLPeg.cxx; do not call from Lua.
-- If the current lexer has no _fold function, folding by indentation is
-- performed if the 'fold.by.indentation' property is set.
-- @param text The document text to fold.
-- @param start_pos The position in the document text starts at.
-- @param start_line The line number text starts on.
-- @param start_level The fold level text starts on.
-- @return Table of fold levels.
function fold(text, start_pos, start_line, start_level)
  local folds = {}
  local lexer = _G._LEXER
  if lexer._fold then
    return lexer._fold(text, start_pos, start_line, start_level)
  elseif GetProperty('fold.by.indentation', 1) == 1 then
    local GetIndentAmount, GetFoldLevel, SetFoldLevel =
      GetIndentAmount, GetFoldLevel, SetFoldLevel
    local SC_FOLDLEVELHEADERFLAG, SC_FOLDLEVELWHITEFLAG =
      SC_FOLDLEVELHEADERFLAG, SC_FOLDLEVELWHITEFLAG
    -- Indentation based folding.
    local current_line = start_line
    local prev_level   = start_level
    for indent, line in text:gmatch('([\t ]*)(.-)\r?\n') do
      if #line > 0 then
        local current_level = GetIndentAmount(current_line)
        if current_level > prev_level then -- next level
          local i = current_line - 1
          while folds[i] and folds[i][2] == SC_FOLDLEVELWHITEFLAG do
            i = i - 1
          end
          if folds[i] then
            folds[i][2] = SC_FOLDLEVELHEADERFLAG -- low indent
          end
          folds[current_line] = { current_level } -- high indent
        elseif current_level < prev_level then -- prev level
          if folds[current_line - 1] then
            folds[current_line - 1][1] = prev_level -- high indent
          end
          folds[current_line] = { current_level } -- low indent
        else -- same level
          folds[current_line] = { prev_level }
        end
        prev_level = current_level
      else
        folds[current_line] = { prev_level, SC_FOLDLEVELWHITEFLAG }
      end
      current_line = current_line + 1
    end
    return folds
  end
end

-- The following are utility functions lexers will have access to.

-- common patterns
any = lpeg.P(1)
ascii = lpeg.R('\000\127')
extend = lpeg.R('\000\255')
alpha = lpeg.R('AZ', 'az')
digit = lpeg.R('09')
alnum = lpeg.R('AZ', 'az', '09')
lower = lpeg.R('az')
upper = lpeg.R('AZ')
xdigit = lpeg.R('09', 'AF', 'af')
cntrl = lpeg.R('\000\031')
graph = lpeg.R('!~')
print = lpeg.R(' ~')
punct = lpeg.R('!/', ':@', '[\'', '{~')
space = lpeg.S('\t\v\f\n\r ')

newline = lpeg.S('\r\n\f')^1
nonnewline = 1 - newline
nonnewline_esc = 1 - (newline + '\\') + '\\' * any

dec_num = digit^1
hex_num = '0' * lpeg.S('xX') * xdigit^1
oct_num = '0' * lpeg.R('07')^1
integer = lpeg.S('+-')^-1 * (hex_num + oct_num + dec_num)
float = lpeg.S('+-')^-1 *
  (digit^0 * '.' * digit^1 + digit^1 * '.' * digit^0 + digit^1) *
  lpeg.S('eE') * lpeg.S('+-')^-1 * digit^1
word = (alpha + '_') * (alnum + '_')^0

---
-- Creates an LPeg capture table index with the name and position of the token.
-- @param name The name of token. If this name is not in `l.tokens` then you
--   will have to specify a style for it in `lexer._tokenstyles`.
-- @param patt The LPeg pattern associated with the token.
-- @usage local ws = token('whitespace', l.space^1)
-- @usage php_start_rule = token('php_tag', '<?' * ('php' * l.space)^-1)
function token(name, patt)
  return lpeg.Ct(lpeg.Cc(name) * patt * lpeg.Cp())
end

-- common tokens
any_char = token('default', any)

---
-- Creates a Scintilla style from a table of style properties.
-- @param style_table A table of style properties.
-- Style properties available:
--   font         = [string]
--   size         = [integer]
--   bold         = [boolean]
--   italic       = [boolean]
--   underline    = [boolean]
--   fore         = [integer]*
--   back         = [integer]*
--   eolfilled    = [boolean]
--   characterset = ?
--   case         = [integer]
--   visible      = [boolean]
--   changeable   = [boolean]
--   hotspot      = [boolean]
-- * Use the value returned by `color()`.
-- @usage local bold_italic = style { bold = true, italic = true }
-- @see color
function style(style_table)
  setmetatable(style_table, {
    __concat = function(t1, t2)
      local t = {} -- duplicate t1 so t1 is unmodified
      for k,v in pairs(t1) do t[k] = v end
      for k,v in pairs(t2) do t[k] = v end
      return t
    end
  })
  return style_table
end

---
-- Creates a Scintilla color.
-- @param r The string red component of the hexadecimal color.
-- @param g The string green component of the color.
-- @param b The string blue component of the color.
-- @usage local red = color('FF', '00', '00')
function color(r, g, b) return tonumber(b..g..r, 16) end

---
-- Creates an LPeg pattern that matches a range of characters delimitted by a
-- specific character(s).
-- This can be used to match a string, parenthesis, etc.
-- @param chars The character(s) that bound the matched range.
-- @param escape Optional escape character. This parameter may be omitted, nil,
--   or the empty string.
-- @param end_optional Optional flag indicating whether or not an ending
--   delimiter is optional or not. If true, the range begun by the start
--   delimiter matches until an end delimiter or the end of the input is
--   reached.
-- @param balanced Optional flag indicating whether or not a balanced range is
--   matched, like `%b` in Lua's `string.find`. This flag only applies if
--   `chars` consists of two different characters (e.g. '()').
-- @param forbidden Optional string of characters forbidden in a delimited
--   range. Each character is part of the set.
-- @usage local sq_str_noescapes = delimited_range("'")
-- @usage local sq_str_escapes = delimited_range("'", '\\', true)
-- @usage local unbalanced_parens = delimited_range('()', '\\', true)
-- @usage local balanced_parens = delimited_range('()', '\\', true, true)
function delimited_range(chars, escape, end_optional, balanced, forbidden)
  local s = chars:sub(1, 1)
  local e = #chars == 2 and chars:sub(2, 2) or s
  local range
  local b = balanced and s or ''
  local f = forbidden or ''
  if not escape or escape == '' then
    local invalid = lpeg.S(e..f..b)
    range = any - invalid
  else
    local invalid = lpeg.S(e..f..b) + escape
    range = any - invalid + escape * any
  end
  if balanced and s ~= e then
    return lpeg.P{ s * (range + lpeg.V(1))^0 * e }
  else
    if end_optional then e = lpeg.P(e)^-1 end
    return s * range^0 * e
  end
end

---
-- Similar to `delimited_range()`, but includes embedded patterns.
-- This is useful for embedding additional lexers inside strings. Do not enclose
-- this range with `token()`. Instead specify the token name in the `token_name`
-- parameter.
-- @param chars The character(s) that bound the matched range.
-- @param escape Escape character or nil.
-- @param token_name Token name for the characters in the range excluding the
--   embedded pattern. Use this instead of `token()`.
-- @param patt Pattern embedded in the range.
-- @param forbidden Optional string of characters forbidden in a delimited
--   range. Each character is part of the set.
-- @usage local embedded_sq_str = l.delimited_range_with_embedded("'", '\\',
--   'string', php_rule)
function delimited_range_with_embedded(chars, escape, token_name, patt, forbidden)
  local s = chars:sub(1, 1)
  local e = #chars == 2 and chars:sub(2, 2) or s
  local range, invalid, valid
  local f = forbidden or ''
  if not escape or escape == '' then
    invalid = patt + lpeg.S(e..f)
    valid = token(id, (any - invalid)^1)
  else
    invalid = patt + lpeg.S(e..f) + escape
    valid = token(id, (any - invalid + escape * any)^1)
  end
  range = lpeg.P { (patt + valid * lpeg.V(1))^0 }
  return token(id, s) * range^-1 * token(id, e)
end

---
-- Creates an LPeg pattern from a given pattern that matches the beginning of a
-- line and returns it.
-- @param patt The LPeg pattern to match at the beginning of a line.
-- @usage local preproc = token('preprocessor', #P('#') * l.starts_line('#' *
--   l.nonnewline^0))
function starts_line(patt)
  return lpeg.P(function(input, idx)
    if idx == 1 then return idx end
    local char = input:sub(idx - 1, idx - 1)
    if char == '\n' or char == '\r' or char == '\f' then return idx end
  end) * patt
end

---
-- Similar to `delimited_range()`, but allows for multi-character delimitters.
-- This is useful for lexers with tokens such as nested block comments. With
-- single-character delimiters, this function is identical to
-- `delimited_range(start_chars..end_chars, nil, end_optional, true)`.
-- @param start_chars The string starting a nested sequence.
-- @param end_chars The string ending a nested sequence.
-- @param end_optional Optional flag indicating whether or not an ending
--   delimiter is optional or not. If true, the range begun by the start
--   delimiter matches until an end delimiter or the end of the input is
--   reached.
-- @usage local nested_comment = l.nested_pair('/*', '*/', true)
function nested_pair(start_chars, end_chars, end_optional)
  local s, e = start_chars, end_optional and lpeg.P(end_chars)^-1 or end_chars
  return lpeg.P{ s * (any - s - end_chars + lpeg.V(1))^0 * e }
end

---
-- Creates an LPeg pattern that matches a set of words.
-- @param words A table of words.
-- @param word_chars Optional string of additional characters considered to be
--   part of a word (default is `%w_`).
-- @param case_insensitive Optional boolean flag indicating whether the word
--   match is case-insensitive.
-- @usage local keyword = token('keyword', word_match { 'foo', 'bar', 'baz' })
-- @usage local keyword = token('keyword', word_match({ 'foo-bar', 'foo-baz',
--   'bar-foo', 'bar-baz', 'baz-foo', 'baz-bar' }, '-', true))
function word_match(words, word_chars, case_insensitive)
  local word_list = {}
  for _, word in ipairs(words) do word_list[word] = true end
  local chars = '%w_'
  -- escape 'magic' characters
  -- TODO: append chars to the end so ^_ can be passed for not including '_'s
  if word_chars then chars = chars..word_chars:gsub('([%^%]%-])', '%%%1') end
  return lpeg.P(function(input, index)
      local s, e, word = input:find('^(['..chars..']+)', index)
      if word then
        if case_insensitive then word = word:lower() end
        return word_list[word] and e + 1 or nil
      end
    end)
end

---
-- Embeds a child lexer language in a parent one.
-- @param parent The parent lexer.
-- @param child The child lexer.
-- @param start_rule The token that signals the beginning of the embedded
--   lexer.
-- @param end_rule The token that signals the end of the embedded lexer.
-- @param preproc Boolean flag specifying if the child lexer is a preprocessor
--   language.
-- @usage embed_lexer(_M, css, css_start_rule, css_end_rule)
-- @usage embed_lexer(html, _M, php_start_rule, php_end_rule, true)
-- @usage embed_lexer(html, ruby, ruby_start_rule, rule_end_rule, true)
function embed_lexer(parent, child, start_rule, end_rule, preproc)
  -- Add child rules.
  if not child._EMBEDDEDRULES then
---
-- Set of rules for an embedded lexer.
-- For a parent lexer name, contains child's `start_rule`, `token_rule`, and
-- `end_rule` patterns.
-- @class table
-- @name _EMBEDDEDRULES
    child._EMBEDDEDRULES = {}
  end
  if not child._RULES then -- creating a child lexer to be embedded
    if not child._rules then error('Cannot embed language with no rules') end
    for _, r in ipairs(child._rules) do add_rule(child, r[1], r[2]) end
  end
  child._EMBEDDEDRULES[parent._NAME] = {
    ['start_rule'] = start_rule,
    token_rule = join_tokens(child),
    ['end_rule'] = end_rule
  }
  if not parent._CHILDREN then
    parent._CHILDREN = {}
    parent._CHILDREN.preproc = {}
  end
  local children = parent._CHILDREN
  children[#children + 1] = child
  local children_preproc = children.preproc
  if preproc then children_preproc[#children_preproc + 1] = child end
  -- Add child styles.
  local tokenstyles = parent._tokenstyles
  for _, style in ipairs(child._tokenstyles or {}) do
    tokenstyles[#tokenstyles + 1] = style
  end
  -- Add child's embedded lexers.
--  local children2 = child._CHILDREN
--  if children2 then
--    for _, child2 in ipairs(children2) do
--      child2._EMBEDDEDRULES[parent._NAME] = child2._EMBEDDEDRULES[child._NAME]
--      children[#children + 1] = child2
--    end
--    for _, child2 in ipairs(children2.preproc) do
--      children_preproc[#children_preproc + 1] = child2
--    end
--  end
end

-- Registered functions and constants.

---
-- Returns the integer style number at a given position.
-- @param pos The position to get the style for.
function get_style_at(pos) end
get_style_at = GetStyleAt

---
-- Returns an integer property value for a given key.
-- @param key The property key.
-- @param default Optional integer value to return if key is not set.
function get_property(key, default) end
get_property = GetProperty

---
-- Returns the fold level for a given line.
-- This level already has `SC_FOLDLEVELBASE` added to it, so you do not need to
-- add it yourself.
-- @param line_number The line number to get the fold level of.
function get_fold_level(line) end
get_fold_level = GetFoldLevel

---
-- Returns the indent amount of text for a given line.
-- @param line The line number to get the indent amount of.
function get_indent_amount(line) end
get_indent_amount = GetIndentAmount

_M.SC_FOLDLEVELBASE = SC_FOLDLEVELBASE
_M.SC_FOLDLEVELWHITEFLAG = SC_FOLDLEVELWHITEFLAG
_M.SC_FOLDLEVELHEADERFLAG = SC_FOLDLEVELHEADERFLAG
_M.SC_FOLDLEVELNUMBERMASK = SC_FOLDLEVELNUMBERMASK

-- Load theme.
if _THEME and _THEME ~= '' then
  local ret, errmsg
  if not _THEME:find('[/\\]') then -- name of stock theme
    ret, errmsg = pcall(dofile, _LEXERHOME..'/themes/'.._THEME..'.lua')
  else -- absolute path of a theme
    ret, errmsg = pcall(dofile, _THEME)
  end
  if not ret and errmsg then _G.print(errmsg) end
end
