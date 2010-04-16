-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Gap LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local comment = token('comment', '#' * l.nonnewline^0)

-- strings
local sq_str = l.delimited_range("'", '\\', true, false, '\n')
local dq_str = l.delimited_range('"', '\\', true, false, '\n')
local string = token('string', sq_str + dq_str)

-- numbers
local number = token('number', l.digit^1 * -l.alpha)

-- keywords
local keyword = token('keyword', word_match {
  'and', 'break', 'continue', 'do', 'elif', 'else', 'end', 'fail', 'false',
  'fi', 'for', 'function', 'if', 'in', 'infinity', 'local', 'not', 'od', 'or',
  'rec', 'repeat', 'return', 'then', 'true', 'until', 'while'
})

-- identifiers
local identifier = token('identifier', l.word)

-- operators
local operator = token('operator', S('*+-,./:;<=>~^#()[]{}'))

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
