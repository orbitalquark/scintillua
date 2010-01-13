-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Java LPeg Lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = '//' * nonnewline_esc^0
local block_comment = '/*' * (any - '*/')^0 * P('*/')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local sq_str = delimited_range("'", '\\', true, false, '\n')
local dq_str = delimited_range('"', '\\', true, false, '\n')
local string = token('string', sq_str + dq_str)

-- numbers
local number = token('number', (float + integer) * S('LlFfDd')^-1)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'abstract', 'assert', 'break', 'case', 'catch', 'class', 'const', 'continue',
  'default', 'do', 'else', 'extends', 'final', 'finally', 'for', 'future',
  'generic', 'goto', 'if', 'implements', 'import', 'inner', 'instanceof',
  'interface', 'native', 'new', 'null', 'outer', 'package', 'private',
  'protected', 'public', 'rest', 'return', 'static', 'super', 'switch',
  'synchronized', 'this', 'throw', 'throws', 'transient', 'try', 'var', 'while',
  'volatile',
  'true', 'false'
}))

-- types
local type = token('type', word_match(word_list{
  'boolean', 'byte', 'char', 'double', 'float', 'int', 'long', 'short', 'void'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('+-/*%<>!=^&|?~:;.()[]{}'))

function LoadTokens()
  local java = java
  add_token(java, 'whitespace', ws)
  add_token(java, 'comment', comment)
  add_token(java, 'string', string)
  add_token(java, 'number', number)
  add_token(java, 'keyword', keyword)
  add_token(java, 'type', type)
  add_token(java, 'identifier', identifier)
  add_token(java, 'operator', operator)
  add_token(java, 'any_char', any_char)
end
