-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Ini LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local comment = token('comment', #S(';#') * l.starts_line(S(';#') * l.nonnewline^0))

-- strings
local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local label = l.delimited_range('[]', nil, true, false, '\n')
local string = token('string', sq_str + dq_str + label)

-- numbers
local dec = l.digit^1 * ('_' * l.digit^1)^0
local oct_num = '0' * S('01234567_')^1
local integer = S('+-')^-1 * (l.hex_num + oct_num + dec)
local number = token('number', (l.float + integer))

-- keywords
local keyword = token('keyword', word_match {
  'true', 'false', 'on', 'off', 'yes', 'no'
})

-- identifiers
local word = (l.alpha + '_') * (l.alnum + S('_.'))^0
local identifier = token('identifier', word)

-- operators
local operator = token('operator', '=')

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

_LEXBYLINE = true
