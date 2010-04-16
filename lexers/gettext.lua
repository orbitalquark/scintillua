-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Gettext LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local comment = token('comment', '#' * S(': .~') * l.nonnewline^0)

-- strings
local string = token('string', l.delimited_range('"', '\\', true, false, '\n'))

-- keywords
local keyword = token('keyword', word_match({
  'msgid', 'msgid_plural', 'msgstr', 'fuzzy', 'c-format', 'no-c-format'
}, '-', true))

-- identifiers
local identifier = token('identifier', l.word)

-- variables
local variable = token('variable', S('%$@') * l.word)

_rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'string', string },
  { 'keyword', keyword },
  { 'identifier', identifier },
  { 'variable', variable },
  { 'any_char', l.any_char },
}
