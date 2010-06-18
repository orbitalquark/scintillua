-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Ada LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local comment = token('comment', '--' * l.nonnewline^0)

-- strings
local string = token('string', l.delimited_range('"', nil, true, false, '\n'))

-- numbers
local hex_num = 'O' * S('xX') * (l.xdigit + '_')^1
local integer = l.digit^1 * ('_' * l.digit^1)^0
local float = integer^1 * ('.' * integer^0)^-1 * S('eE') * S('+-')^-1 * integer
local number =
  token('number', hex_num + S('+-')^-1 * (float + integer) * S('LlUuFf')^-3)

-- keywords
local keyword = token('keyword', word_match {
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
})

-- types
local type = token('type', word_match {
  'boolean', 'character', 'count', 'duration', 'float', 'integer', 'long_float',
  'long_integer', 'priority', 'short_float', 'short_integer', 'string'
})

-- identifiers
local identifier = token('identifier', l.word)

-- operators
local operator = token('operator', S(':;=<>&+-*/.()'))

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
