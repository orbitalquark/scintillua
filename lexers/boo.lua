-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Boo LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

local lit_newline = P('\r')^-1 * P('\n')

-- comments
local line_comment = '#' * nonnewline_esc^0
local block_comment = '/*' * (any - '*/')^0 * P('*/')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local sq_str = delimited_range("'", '\\', true, false, '\n')
local dq_str = delimited_range('"', '\\', true, false, '\n')
local triple_dq_str = '"""' * (any - '"""')^0 * P('"""')^-1
local regex = delimited_range('/', '\\', false, false, '\n')
local string = token('string', triple_dq_str + sq_str + dq_str + regex)

-- numbers
local number = token('number', (float + integer) * (S('msdhsfFlL') + 'ms')^-1)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'and', 'break', 'cast', 'continue', 'elif', 'else', 'ensure', 'except', 'for',
  'given', 'goto', 'if', 'in', 'isa', 'is', 'not', 'or', 'otherwise', 'pass',
  'raise', 'ref', 'try', 'unless', 'when', 'while',
  -- definitions
  'abstract', 'callable', 'class', 'constructor', 'def', 'destructor', 'do',
  'enum', 'event', 'final', 'get', 'interface', 'internal', 'of', 'override',
  'partial', 'private', 'protected', 'public', 'return', 'set', 'static',
  'struct', 'transient', 'virtual', 'yield',
  -- namespaces
  'as', 'from', 'import', 'namespace',
  -- other
  'self', 'super', 'null', 'true', 'false'
}))

-- types
local type = token('type', word_match(word_list{
  'bool', 'byte', 'char', 'date', 'decimal', 'double', 'duck', 'float', 'int',
  'long', 'object', 'operator', 'regex', 'sbyte', 'short', 'single', 'string',
  'timespan', 'uint', 'ulong', 'ushort'
}))

-- functions
local func = token('function', word_match(word_list{
  'array', 'assert', 'checked', 'enumerate', '__eval__', 'filter', 'getter',
  'len', 'lock', 'map', 'matrix', 'max', 'min', 'normalArrayIndexing', 'print',
  'property', 'range', 'rawArrayIndexing', 'required', '__switch__', 'typeof',
  'unchecked', 'using', 'yieldAll', 'zip'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('!%^&*()[]{}-=+/|:;.,?<>~`'))

function LoadTokens()
  local boo = boo
  add_token(boo, 'whitespace', ws)
  add_token(boo, 'comment', comment)
  add_token(boo, 'string', string)
  add_token(boo, 'number', number)
  add_token(boo, 'keyword', keyword)
  add_token(boo, 'type', type)
  add_token(boo, 'function', func)
  add_token(boo, 'identifier', identifier)
  add_token(boo, 'operator', operator)
  add_token(boo, 'any_char', any_char)
end
