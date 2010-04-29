-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Latex LPeg lexer

-- Modified by Brian Schott

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local line_comment = '%' * l.nonnewline^0
local block_comment = '\\begin{comment}' * (l.any - '\\end{comment}')^0 *
  '\\end{comment}'
local comment = token('comment', line_comment + block_comment)

-- strings
local math_string = '$$' * (l.any - '$$')^0 * '$$' +
  l.delimited_range('$', '\\', true, false, '\n')
local string = token('string', math_string)

local command = token('keyword', '\\' * l.word)

-- operators
local operator = token('operator', S('$&%#{}'))

_rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'string', string },
  { 'keyword', command },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
