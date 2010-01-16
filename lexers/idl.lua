-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- IDL LPeg Lexer

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
local number = token('number', float + integer)

-- preprocessor
local preproc_word = word_match(word_list{
  'define', 'undef', 'ifdef', 'ifndef', 'if', 'elif', 'else', 'endif',
  'include', 'warning', 'pragma'
})
local preproc =
  token('preprocessor', #P('#') * starts_line('#' * preproc_word) * nonnewline^0)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'abstract', 'attribute', 'case', 'const', 'context', 'custom', 'default',
  'exception', 'enum', 'factory', 'FALSE', 'in', 'inout', 'interface', 'local',
  'module', 'native', 'oneway', 'out', 'private', 'public', 'raises',
  'readonly', 'struct', 'support', 'switch', 'TRUE', 'truncatable', 'typedef',
  'union', 'valuetype'
}))

-- types
local type = token('type', word_match(word_list{
  'any', 'boolean', 'char', 'double', 'fixed', 'float', 'long', 'Object',
  'octet', 'sequence', 'short', 'string', 'unsigned', 'ValueBase', 'void',
  'wchar', 'wstring'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('!<>=+-/*%&|^~.,:;?()[]{}'))

function LoadTokens()
  local idl = idl
  add_token(idl, 'whitespace', ws)
  add_token(idl, 'keyword', keyword)
  add_token(idl, 'type', type)
  add_token(idl, 'identifier', identifier)
  add_token(idl, 'string', string)
  add_token(idl, 'comment', comment)
  add_token(idl, 'number', number)
  add_token(idl, 'preprocessor', preproc)
  add_token(idl, 'operator', operator)
  add_token(idl, 'any_char', any_char)
end
