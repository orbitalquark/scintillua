-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Props LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

module(...)

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local comment = token(l.COMMENT, '#' * l.nonnewline^0)

-- Equals.
local equals = token(l.OPERATOR, '=')

-- Strings.
local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local string = token(l.STRING, sq_str + dq_str)

-- Variables.
local variable = token(l.VARIABLE, '$(' * (l.any - ')')^1 * ')')

-- Colors.
local xdigit = l.xdigit
local color = token('color', '#' * xdigit * xdigit * xdigit * xdigit * xdigit *
                             xdigit)

_rules = {
  { 'whitespace', ws },
  { 'color', color },
  { 'comment', comment },
  { 'equals', equals },
  { 'string', string },
  { 'variable', variable },
  { 'any_char', l.any_char },
}

_tokenstyles = {
  { 'variable', l.style_variable },
  { 'color', l.style_number },
}

_LEXBYLINE = true
