-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- C# LPeg Lexer

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
local ml_str = P('@')^-1 * delimited_range('"', nil, true)
local string = token('string', sq_str + dq_str + ml_str)

-- numbers
local number = token('number', (float + integer) * S('lLdDfFMm')^-1)

-- preprocessor
local preproc_word = word_match(word_list{
  'define', 'elif', 'else', 'endif', 'error', 'if', 'line', 'undef', 'warning',
  'region', 'endregion'
})
local preproc = token('preprocessor',
  #P('#') * starts_line('#' * S('\t ')^0 * preproc_word *
  (nonnewline_esc^1 + space * nonnewline_esc^0)))

-- keywords
local keyword = token('keyword', word_match(word_list{
  'class', 'delegate', 'enum', 'event', 'interface', 'namespace', 'struct',
  'using', 'abstract', 'const', 'explicit', 'extern', 'fixed', 'implicit',
  'internal', 'lock', 'out', 'override', 'params', 'partial', 'private',
  'protected', 'public', 'ref', 'sealed', 'static', 'readonly', 'unsafe',
  'virtual', 'volatile', 'add', 'as', 'assembly', 'base', 'break', 'case',
  'catch', 'checked', 'continue', 'default', 'do', 'else', 'finally', 'for',
  'foreach', 'get', 'goto', 'if', 'in', 'is', 'new', 'remove', 'return', 'set',
  'sizeof', 'stackalloc', 'super', 'switch', 'this', 'throw', 'try', 'typeof',
  'unchecked', 'value', 'void', 'while', 'yield',
  'null', 'true', 'false'
}))

-- types
local type = token('type', word_match(word_list{
  'bool', 'byte', 'char', 'decimal', 'double', 'float', 'int', 'long', 'object',
  'operator', 'sbyte', 'short', 'string', 'uint', 'ulong', 'ushort'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('~!.,:;+-*/<>=\\^|&%?()[]{}'))

function LoadTokens()
  local cs = csharp
  add_token(cs, 'whitespace', ws)
  add_token(cs, 'comment', comment)
  add_token(cs, 'string', string)
  add_token(cs, 'number', number)
  add_token(cs, 'preproc', preproc)
  add_token(cs, 'keyword', keyword)
  add_token(cs, 'type', type)
  add_token(cs, 'identifier', identifier)
  add_token(cs, 'operator', operator)
  add_token(cs, 'any_char', any_char)
end
