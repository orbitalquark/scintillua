-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Ada LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', '--' * nonnewline^0)

-- strings
local string = token('string', delimited_range('"', nil, true, false, '\n'))

-- numbers
local hex_num = 'O' * S('xX') * (xdigit + '_')^1
local integer = digit^1 * ('_' * digit^1)^0
local float = integer^1 * ('.' * integer^0)^-1 * S('eE') * S('+-')^-1 * integer
local number = token('number', hex_num + S('+-')^-1 * (float + integer) * S('LlUuFf')^-3)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'abort', 'abs', 'accept', 'all', 'and', 'begin', 'body', 'case', 'declare',
  'delay', 'do', 'else', 'elsif', 'end', 'entry', 'exception', 'exit', 'for',
  'generic', 'goto', 'if', 'in', 'is', 'loop', 'mod', 'new', 'not', 'null',
  'or', 'others', 'out', 'protected', 'raise', 'record', 'rem', 'renames',
  'requeue', 'reverse', 'select', 'separate', 'subtype', 'task', 'terminate',
  'then', 'type', 'until', 'when', 'while', 'xor',
  -- preprocessor
  'package', 'pragma', 'use', 'with',
  -- function
  'function', 'procedure', 'return',
  -- storage class
  'abstract', 'access', 'aliased', 'array', 'at', 'constant', 'delta', 'digits',
  'interface', 'limited', 'of', 'private', 'range', 'tagged', 'synchronized',
  -- boolean
  'true', 'false'
}))

-- types
local type = token('type', word_match(word_list{
  'boolean', 'character', 'count', 'duration', 'float', 'integer', 'long_float',
  'long_integer', 'priority', 'short_float', 'short_integer', 'string'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S(':;=<>&+-*/.()'))

function LoadTokens()
  local ada = ada
  add_token(ada, 'whitespace', ws)
  add_token(ada, 'keyword', keyword)
  add_token(ada, 'type', type)
  add_token(ada, 'identifier', identifier)
  add_token(ada, 'string', string)
  add_token(ada, 'comment', comment)
  add_token(ada, 'number', number)
  add_token(ada, 'operator', operator)
  add_token(ada, 'any_char', any_char)
end
