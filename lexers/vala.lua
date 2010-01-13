-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Vala LPeg Lexer

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
local ml_str = '@' * delimited_range('"', nil, true)
local string = token('string', sq_str + dq_str + ml_str)

-- numbers
local number = token('number', (float + integer) * S('uUlLfFdDmM')^-1)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'class', 'delegate', 'enum', 'errordomain', 'interface', 'namespace',
  'signal', 'struct', 'using',
  -- modifiers
  'abstract', 'const', 'dynamic', 'extern', 'inline', 'out', 'override',
  'private', 'protected', 'public', 'ref', 'static', 'virtual', 'volatile',
  'weak',
  -- other
  'as', 'base', 'break', 'case', 'catch', 'construct', 'continue', 'default',
  'delete', 'do', 'else', 'ensures', 'finally', 'for', 'foreach', 'get', 'if',
  'in', 'is', 'lock', 'new', 'requires', 'return', 'set', 'sizeof', 'switch',
  'this', 'throw', 'throws', 'try', 'typeof', 'value', 'var', 'void', 'while',
  -- etc.
  'null', 'true', 'false'
}))

-- types
local type = token('type', word_match(word_list{
  'bool', 'char', 'double', 'float', 'int', 'int8', 'int16', 'int32', 'int64',
  'long', 'short', 'size_t', 'ssize_t', 'string', 'uchar', 'uint', 'uint8',
  'uint16', 'uint32', 'uint64', 'ulong', 'unichar', 'ushort'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('+-/*%<>!=^&|?~:;.()[]{}'))

function LoadTokens()
  local vala = vala
  add_token(vala, 'whitespace', ws)
  add_token(vala, 'keyword', keyword)
  add_token(vala, 'type', type)
  add_token(vala, 'identifier', identifier)
  add_token(vala, 'string', string)
  add_token(vala, 'comment', comment)
  add_token(vala, 'number', number)
  add_token(vala, 'operator', operator)
  add_token(vala, 'any_char', any_char)
end
