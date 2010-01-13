-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Gettext LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', '#' * S(': .~') * nonnewline^0)

-- strings
local string = token('string', delimited_range('"', '\\', true, false, '\n'))

-- keywords
local keyword = token('keyword', word_match(word_list{
  'msgid', 'msgid_plural', 'msgstr', 'fuzzy', 'c-format', 'no-c-format'
}, '-', true))

-- identifiers
local identifier = token('identifier', word)

-- variables
local variable = token('variable', S('%$@') * word)

function LoadTokens()
  local gettext = gettext
  add_token(gettext, 'whitespace', ws)
  add_token(gettext, 'comment', comment)
  add_token(gettext, 'string', string)
  add_token(gettext, 'keyword', keyword)
  add_token(gettext, 'identifier', identifier)
  add_token(gettext, 'variable', variable)
  add_token(gettext, 'any_char', any_char)
end
