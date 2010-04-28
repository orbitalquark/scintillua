-- Lilypond LPeg lexer
-- April, 2010 Robert Gieseke

-- TODO Embed Scheme; Notes?, Numbers?

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local line_comment = '%' * l.nonnewline^0
-- TODO block comment
local comment = token('comment', line_comment )

-- strings
local string = token('string', l.delimited_range('"'))

-- keywordscommands
local keyword = token('keyword', '\\' * l.word)

-- operators
local operator = token('operator', S("{}'~<>|"))

local identifier = token('identifier', l.word)

_rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'string', string },
  { 'keyword', keyword },
  { 'operator', operator },
  { 'identifier', identifier},
  { 'any_char', l.any_char },
}
