-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- R LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', '#' * nonnewline^0)

-- strings
local sq_str = delimited_range("'", '\\', true, false, '\n')
local dq_str = delimited_range('"', '\\', true, false, '\n')
local string = token('string', sq_str + dq_str)

-- numbers
local number = token('number', (float + integer) * P('i')^-1)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'break', 'else', 'for', 'if', 'in', 'next', 'repeat', 'return', 'switch',
  'try', 'while', 'Inf', 'NA', 'NaN', 'NULL', 'FALSE', 'TRUE'
}))

-- types
local type = token('type', word_match(word_list{
  'array', 'character', 'complex', 'data.frame', 'double', 'factor', 'function',
  'integer', 'list', 'logical', 'matrix', 'numeric', 'vector'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('<->+*/^=.,:;|$()[]{}'))

function LoadTokens()
  local r = r
  add_token(r, 'whitespace', ws)
  add_token(r, 'keyword', keyword)
  add_token(r, 'type', type)
  add_token(r, 'identifier', identifier)
  add_token(r, 'string', string)
  add_token(r, 'comment', comment)
  add_token(r, 'number', number)
  add_token(r, 'operator', operator)
  add_token(r, 'any_char', any_char)
end
