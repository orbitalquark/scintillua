-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Pike LPeg Lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = '//' * nonnewline_esc^0
local nested_comment = nested_pair('/*', '*/', true)
local comment = token('comment', line_comment + nested_comment)

-- strings
local sq_str = delimited_range("'", '\\', true, false, '\n')
local dq_str = delimited_range('"', '\\', true, false, '\n')
local lit_str = '#' * delimited_range('"', '\\', true)
local string = token('string', sq_str + dq_str + lit_str)

-- numbers
local number = token('number', (float + integer) * S('lLdDfF')^-1)

-- preprocessors
local preproc = token('preprocessor', #P('#') * starts_line('#' * nonnewline^0))

-- keywords
local keyword = token('keyword', word_match(word_list{
  'break', 'case', 'catch', 'continue', 'default', 'do', 'else', 'for',
  'foreach', 'gauge', 'if', 'lambda', 'return', 'sscanf', 'switch', 'while',
  'import', 'inherit',
  -- type modifiers
  'constant', 'extern', 'final', 'inline', 'local', 'nomask', 'optional',
  'private', 'protected', 'public', 'static', 'variant'
}))

-- types
local type = token('type', word_match(word_list{
  'array', 'class', 'float', 'function', 'int', 'mapping', 'mixed', 'multiset',
  'object', 'program', 'string', 'void'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('<>=!+-/*%&|^~@`.,:;()[]{}'))

function LoadTokens()
  local pike = pike
  add_token(pike, 'whitespace', ws)
  add_token(pike, 'comment', comment)
  add_token(pike, 'string', string)
  add_token(pike, 'number', number)
  add_token(pike, 'preproc', preproc)
  add_token(pike, 'keyword', keyword)
  add_token(pike, 'type', type)
  add_token(pike, 'identifier', identifier)
  add_token(pike, 'operator', operator)
  add_token(pike, 'any_char', any_char)
end

function LoadStyles()
  add_style('annotation', style_preproc)
end
