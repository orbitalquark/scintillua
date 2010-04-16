-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Props LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local comment = token('comment', #P('#') * l.starts_line('#' * l.nonnewline^0))

-- equals
local equals = token('operator', '=')

-- strings
local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local string = token('string', sq_str + dq_str)

-- variables
local variable = token('variable', '$(' * (l.any - ')')^1 * ')')

-- colors
local xdigit = l.xdigit
local color = token('color', '#' * xdigit * xdigit * xdigit * xdigit * xdigit * xdigit)

_rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'equals', equals },
  { 'string', string },
  { 'variable', variable },
  { 'color', color },
  { 'any_char', l.any_char },
}

_tokenstyles = {
  { 'variable', l.style_keyword },
  { 'color', l.style_number },
}

_LEXBYLINE = true
