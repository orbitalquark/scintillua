-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.

---
-- Performs lexing of Scintilla documents.
module('lexer', package.seeall)

-- Markdown:
-- ## Overview
--
-- At its heart, all a lexer does is take input text, parse it, and style it
-- accordingly. Dynamic lexers are no different; they are just more flexible
-- than Scintilla's static ones.
--
-- ## Writing a Dynamic Lexer
--
-- #### Introduction
--
-- This may seem like a daunting task, judging by the length of this document,
-- but the process is actually fairly straight-forward. I have just included
-- lots of details to help in understanding the lexer development process.
--
-- In order to set up a dynamic lexer, create a Lua script with your lexer's
-- name as the filename followed by `.lua` in the `lexers/` directory. Then at
-- the top of your lexer, the following must appear:
--
--     module(..., package.seeall)
--
-- Lexers are meant to be modules, not to be loaded in the global namespace. The
-- `...` parameter means this module assumes the name it is being `require`d
-- with. So doing:
--
--     require 'ruby'
--
-- means the lexer will be the table `ruby` in the global namespace. This is
-- useful to know for when a `require`d lexer wants to check if another lexer
-- in particular has been loaded.
--
-- #### Predefined Styles
--
-- Before styling any text you have to define the different styles it can have.
-- The most common styles are provided and available from `lexer/lexer.lua`:
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
-- #### Custom Styles
--
-- If the default styles are not enough for you, you can create new styles with
-- [`style()`](#style):
--
--     style_bold = style { bold = true }
--
-- You can also use existing styles with modified or added fields when creating
-- a new style:
--
--     style_normal = style_bold..{ bold = false }
--     style_bold_italic = style_bold..{ italic = true }
--
-- Note in both cases that `style_bold` is left unchanged.
--
-- #### Predefined Colors
--
-- Like predefined common styles, common [colors](#colors) are provided and
-- available from `lexer/lexer.lua`.
--
-- #### Predefined Patterns
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
-- * `any_char`: token defined as `token('default', any)`.
--
-- There are also functions to help you construct common patterns. They are
-- listed towards the bottom of this document.
--
-- #### Basic Construction of Patterns with LPeg
--
-- It is time to begin defining the patterns to match various entities in your
-- language like comments, strings, numbers, etc. There are various shortcut
-- functions described in the LuaDoc below in addition to the predefined
-- patterns listed earlier to aid in your endeavor. LPeg's [Documentation][LPeg]
-- is invaluable. You might also find the lexers in `lexers/` helpful.
--
-- [LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
--
-- #### Constructing Keyword Lists with LPeg
--
-- Okay, so at this time you're probably thinking about keywords and keyword
-- lists that were provided in SciTE properties files because you surely will
-- want to style those! Unfortunately there is no way to read those keywords,
-- but there are a couple functions that will make your life easier. Rather than
-- than creating a `lpeg.P('keyword1') + lpeg.P('keyword2') + ...` pattern for
-- keywords, you can use a combination of [`word_list()`](#word_list) and
-- [`word_match()`](#word_match):
--
--     local keywords = word_list{ 'foo', 'bar', 'baz' }
--     local keyword = word_match(keywords)
--
-- These functions make sense to have because the maximum LPeg pattern size for
-- a lexer is SHRT_MAX - 10, or generally 32757 elements. If a `lpeg.P` was
-- created for each keyword in a language, this number would probably come into
-- effect, especially for embedded languages. Also, it would be SLOW to have a
-- pattern for every keyword. [`word_match()`](#word_match) gets the identifier
-- once and checks if it exists in `word_list` using a hash, which is very fast.
--
-- #### Tokens
--
-- Each lexer is composed of a series of tokens, each of which consists of a
-- unique type and an associated LPeg pattern. This type will later be assigned
-- to a style for styling. There are default [types](#types) you can use. Create
-- a token with a specified pattern by calling [`token()`](#token):
--
--     local comment = token('comment', comment_pattern)
--     local variable = token('my_variable', var_pattern)
--
-- Note that `'comment'` is a default type while `'my_variable'` is not. The
-- latter must have a style assigned to while the former does not because a
-- default one has already been assigned (though you can assign a different one
-- if you would like).
--
-- #### Adding Tokens to a Lexer
--
-- Once all tokens have been created, they can be added to your lexer via a
-- `LoadTokens` function using [`add_token()`](#add_token):
--
--     function LoadTokens()
--       add_token(mylexer, 'comment', comment)
--       add_token(mylexer, 'variable', variable)
--     end
--
-- [`add_token()`](#add_token) adds your token to a
-- [`TokenPatterns`](#TokenPatterns) table. This table is available to any other
-- lexer as a means of accessing or modifying your lexer's tokens. This is
-- especially useful for embedded lexer functionality. See the section 'Writing
-- a lexer that will embed in another lexer' for more details.
--
-- Keep in mind order matters. If the match to the first token added fails, the
-- next token is tried, then the next, etc. If you want one token to match
-- before another, move its declaration before the latter's. Not having tokens
-- in proper order can be tricky to debug if something goes wrong.
--
-- #### Bad Input
--
-- It is likely your lexer will, at some point, encounter input that does not
-- match any of your tokens. This can occur as the user is typing only part of a
-- token you recognize (such as a literal string). It can also occur when the
-- code being styled has syntax errors in it. Regardless of how it happens, your
-- lexer will stop styling. Obviously this is not desirable. You have two
-- options:
--
-- * Skip over the bad input until you find familiar tokens again.
-- * Style the bad input as erroneous and continue.
--
-- The predefined `any_char` token becomes useful for skipping bad input. It
-- matches any single character and moves on. Add it to the end of `LoadTokens`:
--
--     add_token(mylexer, 'any_char', any_char)
--
-- If you prefer to style the input as an error, create a token that matches
-- any single character, but with a type of your choosing, such as `'error'`.
-- Then add it to the end of `LoadTokens`.
--
-- #### Adding Styles to a Lexer
--
-- It is time to assign the styles to be applied to tokens. Each lexer has
-- `Types` and `Styles` tables associating how each token type will be styled.
-- These tables are initially populated with `lexers/lexer.lua`'s
-- [`DefaultTypesAndStyles()`](#DefaultTypesAndStyles).
--
-- If the only token types you used were default ones and you are okay with
-- using the default styles, they have already been added to your lexer and
-- nothing else needs to be done. This saves you some time.
--
-- If you defined a new token type or want to associate a different style with
-- a token type, create a `LoadStyles` function. Regardless of whether or not
-- the token type you are assigning a style to is new, you will use
-- [`add_style()`](#add_style) to associate a style to a token type:
--
--     function LoadStyles()
--       add_style('variable', style_variable)
--       add_style('function', style_function)
--     end
--
-- [`add_style()`](#add_style) adds the style and its associated token type to
-- the lexer's `Types` and `Styles` tables respectively.
--
-- #### Lexing Methods
--
-- There are three ways your document can be lexed:
--
-- 1. Lex the document a chunk at a time.
--
--    This is the default method and no further changes to your lexer are
--    necessary.
-- 2. Lex the document line by line.
--
--    Set a `LexByLine` variable to true.
-- 3. Lex the document using a custom function:
--
--         function Lex(text)
--
--         end
--
--   `Lex` must return a table whose indices contain style numbers and positions
--   in the document to style up to with that style number. The LPeg table
--   capture for a lexer is defined as `Tokens` and the pattern to match a
--   single token is defined as `Token`.
--
-- #### Code Folding (Optional)
--
-- It is sometimes convenient to "fold", or not show blocks of code when
-- editing, whether they be functions, classes, comments, etc. The basic idea
-- behind implementing a folder is to iterate line by line through the document,
-- assigning a fold level to each line. Lines to be "hidden" have a higher fold
-- level than lines that are the "fold header"s. This means that when you click
-- the "fold header", it folds all lines below that have a higher fold level
-- than it.
--
-- In order to implement a folder, define the following function in your lexer:
--
--     function Fold(input, start_pos, start_line, start_level)
--
--     end
--
-- * `input`: the text to fold.
-- * `start_pos`: current position in the buffer of the text (used for obtaining
--   style information from the document).
-- * `start_line`: the line number the text starts at.
-- * `start_level`: the fold level of the text at start_line.
--
-- `Fold` should return a table whose indices are line numbers and values are
-- tables containing the fold level and optionally a fold flag.
--
-- The following Scintilla fold constants are also available:
--
-- * `SC_FOLDLEVELBASE`: initial fold level.
-- * `SC_FOLDLEVELWHITEFLAG`: indicates the line is blank and allows it to be
--   considered part of the preceding section even though it may have a lesser
--   fold level.
-- * `SC_FOLDLEVELHEADERFLAG`: indicates the line is a header (fold point).
-- * `SC_FOLDLEVELNUMBERMASK`: used in conjunction with `SCI_GETFOLDLEVEL(line)`
--   to get the fold level of a line.
--
-- An important one to remember is `SC_FOLDLEVELBASE` which is the value you
-- will add your fold levels to if you are not using the previous line's fold
-- level at all (e.g. folding by indent level).
--
-- Now you will want to iterate over each line, setting fold levels as well as
-- keeping track of the line number you're on, the current position at the end
-- of each line, and the fold level of the previous line. As an example:
--
--     local folds = {}
--     local current_line = start_line
--     local prev_level   = start_level
--     for line in text:gmatch('(.-)\r?\n') do
--       if #line > 0 then
--         local header
--         -- code to determine if this will be a header level
--         if header then
--           -- header level flag
--           folds[current_line] = { prev_level, SC_FOLDLEVELHEADERFLAG }
--           current_level = current_level + ...
--         else
--           -- code to determine fold level, and add (+) it to
--           -- current_level
--           current_level = current_level + ...
--           folds[current_line] = { current_level }
--         end
--         prev_level = current_level
--       else
--         -- empty line flag
--         folds[current_line] = { prev_level, SC_FOLDLEVELWHITEFLAG)
--       end
--       current_line = current_line + 1
--     end
--     return folds
--
-- Lua functions to help you fold your document:
--
-- * **GetFoldLevel** (line)<br />
--   Returns the fold level + `SC_FOLDLEVELBASE` of `line`.
-- * **GetStyleAt** (position)<br />
--   Returns the integer style at position.
-- * **GetIndentAmount** (line\_number)<br />
--   Returns the indent amount of `line_number` (taking into account tabsize,
--   tabs or spaces, etc.)
-- * **GetProperty** (key)<br />
--   Returns the integer property for `key`.
--
-- Note: do not use `GetProperty` for getting fold options from a `.properties`
-- file because SciTE needs to be compiled to forward those specific properties
-- to Scintilla. Instead, provide options that can be set at the top of your
-- lexer.
--
-- There is a new `fold.by.indentation` property where if the `fold` property is
-- set for a lexer, but there is no `Fold` function available, the document is
-- folded by indentation. This is done in `lexers/lexer.lua` and should serve as
-- an example of folding in this manner.
--
-- #### Using the Lexer with SciTE
--
-- Congratulations! You have finished writing a dynamic lexer. Now you can
-- either create a properties file for it (don't forget to 'import' it in your
-- Global or User properties file), or elsewhere define the necessary
--
--     file.patterns.[lexer_name]=[file_patterns]
--     lexer.$(file.patterns.[lexer_name])=[lexer_name]
--
-- in order for the lexer to be loaded automatically when a specific file type
-- is opened.
--
-- Because you have your styles and colors defined in the lexer itself, you may
-- be wondering if your SciTE properties files can still be used. The answer is
-- absolutely! All styling information is ignored though.
--
-- #### Embedding a Language in your Lexer
--
-- 1. Load the child lexer module by doing something like:
--
--         local child = require('child_lexer')
-- 2. Load the child lexer's styles in the `LoadStyles` function.
--
--         child.LoadStyles()
-- 3. Load the child lexer's tokens in the `LoadTokens` function.
--
--         child.LoadTokens()
-- 4. In the parent's `LoadTokens` function, use
--    [`embed_language()`](#embed_language). The `html.lua` lexer is a good
--    example.
--
-- No modifications of the child lexer should be necessary. This means any
-- lexers you write can be embedded in a parent lexer.
--
-- #### Writing a Lexer that Will Embed in Another Lexer
--
-- 1. Load the parent lexer module that you will embed your child lexer into by
--    doing something like:
--
--         local parent = require('parent_lexer')
-- 2. In the `LoadTokens` function, create start and end tokens for your child
--    lexer. They are tokens that define the start and end of your embedded
--    lexer respectively. For example, PHP requires a `<?php` to start, and a
--    `?>` to end. Then modify your lexer's `any_char` token (or equivalent, via
--    the `TokenPattern` table) to a character that does not match the end
--    token. Finally, call [`make_embeddable()`](#make_embeddable):
--
--         local start_token = foo
--         local end_token = bar
--         child.TokenPatterns.any_char = token('default', 1 - end_token)
--         make_embeddable(child, parent, start_token, end_token)
-- 3. Use [`embed_language()`](#embed_language). (Note the `SHRT_MAX` limitation
--    may come into effect.)
-- 4. Load the parent lexer's styles in the `LoadStyles` function.
--
--         parent.LoadStyles()
-- 5. Load the parent lexer's tokens in the `LoadTokens` function.
--
--         parent.LoadTokens()
-- 6. If your embedded lexer is a preprocessor language, you may want to modify
--    some of parent's tokens to embed your lexer in (i.e. strings). You can
--    access them through the parent's [`TokenPatterns`](#TokenPatterns). Then
--    you must rebuild the parent's token patterns by calling
--    [`rebuild_token()`](#rebuild_token) and
--    [`rebuild_tokens()`](#rebuild_tokens) one after the other passing the
--    parent lexer as the only parameter:
--
--         parent.TokenPatterns.string = string_with_embedded
--         rebuild_token(parent)
--         rebuild_tokens(parent)
-- 7. If your child lexer, not the parent lexer, is being loaded, specify that
--    you want the parent's tokens to be used for lexing instead of child's. Set
--    a global `UseOtherTokens` variable to be parent's tokens:
--
--         UseOtherTokens = parent.Tokens
--
--    The `php.lua` lexer is a good example.
--
-- #### Optimization
--
-- Lexers can usually be optimized for speed by re-arranging tokens so that the
-- most common ones are recognized first. Be careful that by putting some tokens
-- in front of others, the latter tokens may not be recognized because the
-- former tokens may "eat" them because they match first.
--
-- #### Effects on SciTE-tools and SciTE-st Lua modules
--
-- Because most custom styles are not fixed numbers, both scope-specific
-- snippets and key commands need to be tweaked a bit. `SCE_*` scope constants
-- are no longer available. Instead, named keys are scopes in that lexer. See
-- `lexers/lexer.lua` for default named scopes. Each individual lexer uses
-- [`add_style()`](#add_style) to add additional styles/scopes to it, so use the
-- string argument passed as the scope's name.
--
-- #### Additional Lexer Examples
--
-- See the lexers contained in `lexers/`.
--
-- #### Troubleshooting
--
-- Lexers can be tricky to debug if you do not write them carefully. Errors are
-- printed to STDOUT as well as any `print()` statements in the lexer itself.
--
-- #### Limitations
--
-- Patterns can only be comprised of `SHRT_MAX` - 10 or generally 32757
-- elements. This should be suitable for most language lexers however.
--
-- #### Performance
--
-- Single-language lexers are nearly as efficient as Scintilla's lexers. They
-- utilize Scintilla's internal `endStyled` variable so the entire document
-- does not have to be lexed each time. A little bit of backtracking might be
-- necessary to ensure the accuracy of the LPeg parsing, but only by a small
-- number of characters.
--
-- Lexers with embedded languages will see reduced performance because the
-- entire document must be lexed each time. If `endStyled` was used, the LPeg
-- lexer would not know if the start position is inside the child language or
-- the parent one. Even if it knew it was in the child one, there is no entry
-- point for the pattern.
--
-- #### Disclaimer
--
-- Because of its dynamic nature, crashes could potentially occur because of
-- malformed lexers. In the event that this happens, I CANNOT be liable for any
-- damages such as loss of data. You are encouraged, however, to report the
-- crash with any information that can produce it, or submit a patch to me that
-- fixes the error.
--
-- #### Acknowledgements
--
-- When Peter Odding posted his original Lua lexer to the Lua mailing list, it
-- was just what I was looking for to start making the LPeg lexer I had been
-- dreaming of since Roberto announced the library. Until I saw his code, I
-- was not sure what the best way to go about implementing a lexer was, at
-- least one that Scintilla could utilize. I liked the way he tokenized
-- patterns, because it was really easy for me to assign styles to them. I also
-- learned much more about LPeg through his amazingly simple, but effective
-- script.

-- Path to lexers and libraries.
if not WIN32 then
  package.path  = lexer_home..'/?.lua'
  package.cpath = lexer_home..'/?.so'
else
  package.path  = lexer_home..'/?.lua'
  package.cpath = lexer_home..'/?.dll'
end

if not _G.lpeg then _G.lpeg = require 'lpeg' end
local lpeg = _G.lpeg

---
-- Initializes the lexer language.
-- Called by LexLPeg.cxx to initialize lexer.
-- @param name The name of the lexing language.
function InitLexer(name)
  _G.Lexer = require(name or 'container')
  local Lexer = Lexer
  if Lexer then
    -- load styles
    Lexer.Types, Lexer.Styles = DefaultTypesAndStyles()
    if Lexer.LoadStyles then Lexer.LoadStyles() end
    -- load tokens
    if Lexer.LoadTokens then
      Lexer.LoadTokens()
      if not Lexer.UseOtherTokens then
        rebuild_token(Lexer)
        rebuild_tokens(Lexer)
      else
        Lexer.Tokens = Lexer.UseOtherTokens
      end
    end
  else
    error('Lexer '..name..'does not exist')
  end
end

---
-- Performs the lexing of the document, returning a table of tokens for styling
-- by Scintilla.
-- Called by LexLPeg.cxx to lex the document.
-- If the lexer has a LexByLine flat set, the document is lexed one line at a
-- time. If the lexer has a specific Lex function, it is used to lex the
-- document. Otherwise, the entire document is lexed at once.
-- @param text The text to lex.
-- @return A table of tokens. lpeg.match returns a table of tokens. Each token
-- contains a string identifier ('comment', 'string', etc.) and a position in
-- the document the identifier applies to.
function RunLexer(text)
  local tokens = {}
  local Lexer, StyleTo = Lexer, StyleTo

  -- Get the tokens in order to style the text.
  if not Lexer.LexByLine then -- lex whole document
    return Lexer.Lex and Lexer.Lex(text) or lpeg.match(Lexer.Tokens, text)
  else -- lex document line by line
    local function append(tokens, line_tokens, offset)
      for _, token in ipairs(line_tokens) do
        token[2] = token[2] + offset
        tokens[#tokens + 1] = token
      end
    end
    local offset = 0
    local Tokens = Lexer.Tokens
    for line in text:gmatch('[^\n\r\f]*[\n\r\f]*') do
      if line then
        local line_tokens = lpeg.match(Tokens, line)
        if line_tokens then append(tokens, line_tokens, offset) end
        offset = offset + #line
        -- Use the default style to the end of the line if none was specified.
        if tokens[#tokens][2] ~= offset then
          tokens[#tokens + 1] = { 'default', offset + 1 }
        end
      end
    end
    return tokens
  end
end

---
-- Performs the folding of the document.
-- Called by LexLPeg.cxx to fold the document. If the current Lexer has no Fold
-- function, folding by indentation is performed unless forbidden by the
-- 'fold.by.indentation' property.
-- @param text The document text to fold.
-- @param start_pos The position in the document text starts at.
-- @param start_line The line number text starts on.
-- @param start_level The fold level text starts on.
function RunFolder(text, start_pos, start_line, start_level)
  local folds = {}
  local Lexer = Lexer
  if Lexer.Fold then
    return Lexer.Fold(text)
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

---
-- Creates an LPeg capture table index with the id and position of the capture.
-- @param type The type of token that patt is. If your lexer will be embedded in
--   another one, it is recommended to prefix type with something unique to your
--   lexer. You must have a style assigned to this token type.
-- @param patt The LPeg pattern associated with the identifier.
-- @usage local comment = token('comment', comment_pattern) creates a token
--   using the default 'comment' identifier.
-- @usage local my_var = token('my_variable', variable_pattern) creates a token
--   using a custom identifier. Don't forget to use the add_style function to
--   associate this identifer with a style.
-- @see add_style
function token(type, patt)
  return lpeg.Ct( lpeg.Cc(type) * patt * lpeg.Cp() )
end

---
-- Adds a token to a lexer's current ordered list of tokens.
-- @param lexer The lexer adding the token to.
-- @param id The string identifier of patt. It is used for other lexers to
--   access this particular pattern. It does not have to be the same as the
--   type passed to 'token'.
-- @param token_patt The LPeg pattern (returned by the 'token' function)
--   associated with the identifier.
-- @param exclude Optional flag indicating whether or not to exclude this token
--   from lexer.Token when rebuilding. This flag would be set to true when
--   tokens are only meant to be accessible to other lexers in the
--   lexer.TokenPatterns table.
-- @param pos Optional index to insert this token in TokenOrder.
-- @usage add_token(lexer, 'comment', comment_token) adds a 'comment' token to
--   the current list of tokens in lexer used to build the Tokens pattern used
--   to style input. The value of comment_token in this case would be the value
--   returned by token('comment', comment_pattern)
function add_token(lexer, id, token_patt, exclude, pos)
  if not lexer then error('add_token() given a nil lexer value') end
  if not lexer.TokenOrder then
---
-- Ordered list of token identifiers for a specific lexer.
-- Contains an ordered list (by numerical index) of token identifier strings.
-- This is used in conjunction with TokenPatterns for building the Token and
-- Tokens lexer variables. This table doesn't need to be modified manually, as
-- calls to the 'add_token' function update this list appropriately.
-- @class table
-- @name TokenOrder
-- @see rebuild_token
-- @see rebuild_tokens
    lexer.TokenOrder = {}
---
-- List of token identifiers with associated LPeg patterns for a specific
-- lexer.
-- It provides a public interface to this lexer's tokens by other lexers. This
-- list is used in conjunction with TokenOrder and also doesn't need to be
-- modified manually.
-- @class table
-- @name TokenPatterns
-- @see rebuild_token
-- @see rebuild_tokens
    lexer.TokenPatterns = {}
  end
  local order, patterns = lexer.TokenOrder, lexer.TokenPatterns
  if not exclude then
    if pos then
      table.insert(order, pos, id)
    else
      order[#order + 1] = id
    end
  end
  patterns[id] = token_patt
end

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

-- common tokens
any_char = token('default', any)

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
--   reached. This is useful for finding unmatched delimiters.
-- @param balanced Optional flag indicating whether or not that a a balanced
--   range is matched. This flag only applies if 'chars' consists of two
--   different characters, like parenthesis for example. Any character
--   indicating the start of a range requires its end complement. When the
--   complement of the first range-start character is found, the match ends.
-- @param forbidden Optional string of characters forbidden in a delimited
--   range. Each character is part of the set.
-- @usage local sq_str = delimited_range("'", '\\') creates a pattern that
--   matches a region bounded by "'" characters, but "\'" is not interpreted as
--   a region's end. (It is escaped.)
-- @usage local paren = delimited_range('()') creates a pattern that matches a
--   region contained in parenthesis with no escape character. Note that this
--   does not match a balanced pattern; it interprets the first ')' as the
--   region's end.
-- @usage local paren = delimited_range('()', '\\', true) creates a pattern
--   that matches a region contained in balanced parenthesis with an escape
--   character. So sequences like '\)' are not interpreted as the end of a
--   balanced range.
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
    local invalid = lpeg.S(e..f..escape..b)
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
-- Creates an LPeg pattern that matches a range of characters delimitted by a
-- specific character(s) with an embedded pattern.
-- This is useful for embedding additional lexers inside strings for example.
-- @param chars The character(s) that bound the matched range.
-- @param escape Escape character. If there isn't one, nil or the empty string
--   should be passed.
-- @param id Specifies the identifier used to create tokens that match
--   everything but patt.
-- @param patt Pattern embedded in the range.
-- @param forbidden Optional string of characters forbidden in a delimited
--   range. Each character is part of the set.
-- @usage local sq_str = delimited_range_with_embedded("'", '\\', 'string',
--   emb_language) creates a pattern that matches a region bounded by "'"
--   characters. Any contents in the region that do not match emb_language are
--   styled as the default 'string' identifier, and any contents matching
--   emb_language are styled appropriately as the tokens in emb_language
--   indicate. Basically, emb_language is embedded inside a single quoted
--   string and styled correctly.
function delimited_range_with_embedded(chars, escape, id, patt, forbidden)
  local s = chars:sub(1, 1)
  local e = #chars == 2 and chars:sub(2, 2) or s
  local range, invalid, valid
  local f = forbidden or ''
  if not escape or escape == '' then
    invalid = patt + lpeg.S(e..f)
    valid = token(id, (any - invalid)^1)
  else
    invalid = patt + lpeg.S(e..f..escape)
    valid = token(id, (any - invalid + escape * any)^1)
  end
  range = lpeg.P { (patt + valid * lpeg.V(1))^0 }
  return token(id, s) * range^-1 * token(id, e)
end

---
-- Creates an LPeg pattern from a given pattern that matches the beginning of a
-- line and returns it.
-- @param patt The LPeg pattern to match at the beginning of a line.
-- @usage local preproc = starts_line(lpeg.P('#') * alpha^1) creates a pattern
--   that matches a C preprocessor directive such as '#include'.
function starts_line(patt)
  return lpeg.P(function(input, idx)
    if idx == 1 then return idx end
    local char = input:sub(idx - 1, idx - 1)
    if char == '\n' or char == '\r' or char == '\f' then return idx end
  end) * patt
end

---
-- Creates an LPeg pattern that matches a range of characters delimitted by a
-- set of nested delimitters.
-- Use this function for multi-character delimitters, delimited_range otherwise
-- with balance set to 'true'.
-- This is useful for languages with tokens such as nested block comments.
-- @param start_chars The string starting delimiter character sequence.
-- @param end_chars The string ending delimiter character sequence.
-- @param end_optional Optional flag indicating whether or not an ending
--   delimiter is optional or not. If true, the range begun by the start
--   delimiter matches until an end delimiter or the end of the input is
--   reached. This is useful for finding unmatched delimiters.
-- @usage local nested_comment = nested_pair('/*', '*/', true) creates a pattern
--   that matches a region contained in a nested set of C-style block comments.
function nested_pair(start_chars, end_chars, end_optional)
  local s, e = start_chars, end_optional and lpeg.P(end_chars)^-1 or end_chars
  return lpeg.P{ s * (any - s - end_chars + lpeg.V(1))^0 * e }
end

---
-- Creates a Scintilla color.
-- @param r The red component of the hexadecimal color [string].
-- @param g The green component of the color [string].
-- @param b The blue component of the color [string].
-- @usage local red = color('FF', '00', '00') creates a Scintilla color based
--   on the hexadecimal representation of red.
function color(r, g, b) return tonumber(b..g..r, 16) end

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
-- * Use the value returned by the color function.
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

local ret, errmsg
if color_theme and color_theme ~= '' then
  if not color_theme:find('[/\\]') then
    ret, errmsg = pcall(dofile, lexer_home..'/themes/'..color_theme..'.lua')
  else -- color_theme is a path to a color theme file
    ret, errmsg = pcall(dofile, color_theme)
  end
  if not ret and errmsg then _G.print(errmsg) end
end
if not color_theme or not ret then
---
-- Light theme initial colors.
-- @class table
-- @name colors
-- @field green The color green.
-- @field blue The color blue.
-- @field red The color red.
-- @field yellow The color yellow.
-- @field teal The color teal.
-- @field white The color white.
-- @field black The color black.
-- @field grey The color grey.
-- @field purple The color purple.
-- @field orange The color orange.
-- @field lgreen The color light green.
-- @field lblue The color light blue.
-- @field lred The color light red.
-- @field lyellow The color light yellow.
-- @field lteal The color light teal.
-- @field lpurple The color light purple.
-- @field lorange The color light orange.
-- @see color
colors = {
  green   = color('4D', '99', '4D'),
  blue    = color('4D', '4D', '99'),
  red     = color('99', '4C', '4C'),
  yellow  = color('99', '99', '4D'),
  teal    = color('4D', '99', '99'),
  white   = color('EE', 'EE', 'EE'),
  black   = color('33', '33', '33'),
  grey    = color('AA', 'AA', 'AA'),
  purple  = color('99', '4D', '99'),
  orange  = color('C0', '80', '40'),
  lgreen  = color('80', 'C0', '40'),
  lblue   = color('40', '80', 'C0'),
  lred    = color('C0', '40', '40'),
  lyellow = color('C0', 'C0', '40'),
  lteal   = color('40', 'C0', 'C0'),
  lpurple = color('C0', '40', '80'),
  lorange = color('C0', '80', '40'),
}

-- Useful styles.
style_nothing    = style {                                        }
style_char       = style { fore = colors.red,    bold      = true }
style_class      = style { fore = colors.black,  underline = true }
style_comment    = style { fore = colors.lblue,  bold      = true }
style_constant   = style { fore = colors.teal,   bold      = true }
style_definition = style { fore = colors.red,    bold      = true }
style_error      = style { fore = colors.lred                     }
style_function   = style { fore = colors.blue,   bold      = true }
style_keyword    = style { fore = colors.yellow, bold      = true }
style_number     = style { fore = colors.teal                     }
style_operator   = style { fore = colors.black,  bold      = true }
style_string     = style { fore = colors.green,  bold      = true }
style_preproc    = style { fore = colors.red                      }
style_tag        = style { fore = colors.teal,   bold      = true }
style_type       = style { fore = colors.green                    }
style_variable   = style { fore = colors.red                      }
style_whitespace = style {                                        }
style_embedded   = style_tag..{ back = color('DD', 'DD', 'DD')    }
style_identifier = style_nothing

-- Default styles.
local font_face = '!Bitstream Vera Sans Mono'
local font_size = 10
if WIN32 then
  font_face = '!Courier New'
elseif MAC then
  font_face = '!Monaco'
  font_size = 12
end
style_default = style{
  font = font_face,
  size = font_size,
  fore = colors.black,
  back = colors.white
}
style_line_number = style { fore = colors.black, back = colors.grey }
style_bracelight  = style { fore = color('66', '99', 'FF'), bold = true }
style_bracebad    = style { fore = color('FF', '66', '99'), bold = true }
style_controlchar = style_nothing
style_indentguide = style { fore = colors.grey, back = colors.white }
style_calltip     = style { fore = colors.black, back = color('DD', 'DD', 'DD') }
end

---
-- Returns default Types and Styles common to most every lexer.
-- Note this does not need to be called by the lexer. It is called for the
-- lexer automatically when it is initialized.
-- @return Types and Styles tables.
function DefaultTypesAndStyles()

---
-- [Local table] Default (initial) Types.
-- Contains token identifiers and associated style numbers.
-- @class table
-- @name types
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
  local types = {
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
-- [Local table] Default (initial) Styles.
-- Contains style numbers and associated styles.
-- @class table
-- @name styles
  local styles = {
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

    -- Annotations.
    [512] = style_default,
    [513] = style_comment,
    [514] = style_error,
  }
  return types, styles
end

---
-- Adds a new Scintilla style to Scintilla.
-- @param id An identifier passed when creating a token.
-- @param style A Scintilla style created from style().
-- @usage add_style('comment', my_comment_style) overrides the default style
--   for tokens with default identifier 'comment' with a user-defined style.
-- @usage add_style('my_variable', variable_style) adds a user-defined style
--   for tokens with the identifier 'my_variable'.
-- @see token
-- @see style
function add_style(id, style)
  local len = Lexer.Styles.len
  if len == 32 then len = len + 8 end -- skip predefined styles
  if len < 128 then
    Lexer.Types[id] = len
    Lexer.Styles[len] = style
    Lexer.Styles.len = len + 1
    return len
  else _G.print('Too many styles defined (128 MAX)') end
end

---
-- Allows a child lexer to be embedded in a parent one.
-- An appropriate entry in child.EmbeddedIn is created; then the
-- 'embed_language' function can be called to embed the child lexer in the
-- parent.
-- @param child The child lexer language.
-- @param parent The parent lexer language.
-- @param start_token The token that signals the beginning of the embedded
--   lexer.
-- @param end_token The token that signals the end of the embedded lexer.
function make_embeddable(child, parent, start_token, end_token)
  if not child.EmbeddedIn then child.EmbeddedIn = {} end
  child.EmbeddedIn[parent._NAME] = {}
  local elang = child.EmbeddedIn[parent._NAME]
  elang.start_token = start_token
  elang.token       = rebuild_token(child)
  elang.end_token   = end_token
end

---
-- Embeds a child lexer language in a parent one.
-- The 'make_embeddable' function must be called first to prepare the child
-- lexer for embedding in the parent. The child's tokens are placed before the
-- parent's and maybe inside other embedded lexers depending on the preproc
-- argument.
-- @param parent The parent lexer language.
-- @param child The child lexer language.
-- @param preproc Boolean flag specifying if the child lexer is a preprocessor
--   language. If so, its tokens are placed before all embedded lexers' tokens.
-- @usage embed_language(parent_lang, child_lang) embeds child_lang inside
--   parent_lang, keeping other embedded languages unmodified.
-- @usage embed_language(parent_lang, child_lang, true) embeds child_lang
--   inside parent_lang and all of its other embedded languages.
-- @see make_embeddable
function embed_language(parent, child, preproc)
  if not parent.Token then rebuild_token(parent) end
  local token = parent.Token
  if not parent.languages then
    parent.languages = {}
    parent.languages.preproc = {}
  end
  -- Iterate over all languages embedded in parent, putting all embedded
  -- languages' tokens before parent's tokens.
  for _, elanguage in ipairs(parent.languages) do
    local elang = elanguage.EmbeddedIn[parent._NAME]
    if preproc then
      -- Preprocessor language; add preproc's tokens before each embedded
      -- language's tokens.
      local plang = child.EmbeddedIn[parent._NAME]
      token = elang.start_token * (
        plang.start_token * plang.token^0 * plang.end_token^-1 +
        elang.token
      )^0 * elang.end_token^-1 + token
      parent.languages.preproc[child._NAME] = child
    else
      token = elang.start_token * elang.token^0 * elang.end_token^-1 + token
    end
  end
  parent.languages[#parent.languages + 1] = child
  -- Now add child's tokens before everything else.
  local elang = child.EmbeddedIn[parent._NAME]
  local elang_token = elang.start_token * elang.token^0 * elang.end_token^-1
  parent.Tokens = lpeg.Ct( (elang_token + token)^0 )
end

---
-- (Re)constructs parent.Token.
-- Creates the token pattern from parent.TokenOrder, an ordered list of tokens.
-- Rebuilding is useful for modifying parent's tokens for embedded lexers.
-- Generally calling 'rebuild_tokens' is also necessary after this.
-- @param parent The parent lexer language.
-- @return token pattern (for convenience), but parent.Token is still modified,
--   so setting it manually is not necessary.
-- @see rebuild_tokens
function rebuild_token(parent)
  local patterns, order = parent.TokenPatterns, parent.TokenOrder
  if not (patterns or order) then error('No tokens found') end
  local token = patterns[ order[1] ]
  for i = 2, #parent.TokenOrder do
    if not patterns[ order[i] ] then
      error('One of your tokens is not a pattern')
    end
    token = token + patterns[ order[i] ]
  end
  parent.Token = token
  return token
end

---
-- (Re)constructs parent.Tokens.
-- This is generally called after 'rebuild_token' in order to create the
-- pattern used to lex input.
-- @param parent The parent lexer language.
-- @see rebuild_token
function rebuild_tokens(parent)
  local token = parent.Token
  if parent.languages then
    if #parent.languages.preproc > 0 then
      for _, planguage in ipairs(parent.languages.preproc) do
        local plang = planguage.EmbeddedIn[parent._NAME]
        local eplang = plang.start_token * plang.token^0 * plang.end_token^-1
        -- Add preproc's tokens before tokens of all other embedded languages.
        for _, elanguage in ipairs(parent.languages) do
          if elanguage ~= planguage then
            local elang = elanguage.EmbeddedIn[parent._NAME]
            token = elang.start_token * (eplang + elang.token)^0 *
              elang.end_token^-1 + token
          end
        end
        token = eplang + token
      end
    else
      for _, elanguage in ipairs(parent.languages) do
        local elang = elanguage.EmbeddedIn[parent._NAME]
        token = elang.start_token * elang.token^0 * elang.end_token^-1 + token
      end
    end
  end
  parent.Tokens = lpeg.Ct(token^0)
end

---
-- Creates a table of given words for hash lookup.
-- This is usually used in conjunction with word_match.
-- @param word_table A table of words.
-- @usage local keywords = word_list{ 'foo', 'bar', 'baz' } creates a pattern
--   that matches words 'foo', 'bar', or 'baz'.
-- @see word_match
function word_list(word_table)
  local hash = {}
  for _, v in ipairs(word_table) do hash[v] = true end
  return hash
end

---
-- Creates an LPeg pattern function that checks to see if the current word is
-- in word_list, returning the index of the end of the word. (Thus the pattern
-- succeeds.)
-- @param word_list A word list constructed from word_list.
-- @param word_chars Optional string of additional characters considered to be
--   part of a word.
-- @param case_insensitive Optional boolean flag indicating whether the word
--   match is case-insensitive.
-- @usage local keyword = token('keyword', word_match(word_list{ 'foo', 'bar',
--   'baz' }, nil, true)) creates a token whose pattern matches any of the
--   words 'foo', 'bar', or 'baz' case insensitively.
-- @see word_list
function word_match(word_list, word_chars, case_insensitive)
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

setfenv(0, lexer)
