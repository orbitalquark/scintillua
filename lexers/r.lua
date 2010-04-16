-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- R LPeg lexer

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
local number = token('number', (l.float + l.integer) * P('i')^-1)

-- keywords
local keyword = token('keyword', word_match {
  'break', 'else', 'for', 'if', 'in', 'next', 'repeat', 'return', 'switch',
  'try', 'while', 'Inf', 'NA', 'NaN', 'NULL', 'FALSE', 'TRUE'
})

-- types
local type = token('type', word_match {
  'array', 'character', 'complex', 'data.frame', 'double', 'factor', 'function',
  'integer', 'list', 'logical', 'matrix', 'numeric', 'vector'
})

-- identifiers
local identifier = token('identifier', l.word)

-- operators
local operator = token('operator', S('<->+*/^=.,:;|$()[]{}'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'type', type },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
