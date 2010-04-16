-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Pike LPeg Lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local line_comment = '//' * l.nonnewline_esc^0
local nested_comment = l.nested_pair('/*', '*/', true)
local comment = token('comment', line_comment + nested_comment)

-- strings
local sq_str = l.delimited_range("'", '\\', true, false, '\n')
local dq_str = l.delimited_range('"', '\\', true, false, '\n')
local lit_str = '#' * l.delimited_range('"', '\\', true)
local string = token('string', sq_str + dq_str + lit_str)

-- numbers
local number = token('number', (l.float + l.integer) * S('lLdDfF')^-1)

-- preprocessors
local preproc = token('preprocessor', #P('#') * l.starts_line('#' * l.nonnewline^0))

-- keywords
local keyword = token('keyword', word_match {
  'break', 'case', 'catch', 'continue', 'default', 'do', 'else', 'for',
  'foreach', 'gauge', 'if', 'lambda', 'return', 'sscanf', 'switch', 'while',
  'import', 'inherit',
  -- type modifiers
  'constant', 'extern', 'final', 'inline', 'local', 'nomask', 'optional',
  'private', 'protected', 'public', 'static', 'variant'
})

-- types
local type = token('type', word_match {
  'array', 'class', 'float', 'function', 'int', 'mapping', 'mixed', 'multiset',
  'object', 'program', 'string', 'void'
})

-- identifiers
local identifier = token('identifier', l.word)

-- operators
local operator = token('operator', S('<>=!+-/*%&|^~@`.,:;()[]{}'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'type', type },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'preproc', preproc },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
