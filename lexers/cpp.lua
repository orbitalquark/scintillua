-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- C/C++ LPeg Lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = '//' * nonnewline_esc^0
local block_comment = '/*' * (any - '*/')^0 * P('*/')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local sq_str = P('L')^-1 * delimited_range("'", '\\', true, false, '\n')
local dq_str = P('L')^-1 * delimited_range('"', '\\', true, false, '\n')
local string = token('string', sq_str + dq_str)

-- numbers
local number = token('number', float + integer)

-- preprocessor
local preproc_word = word_match(word_list{
  'define', 'elif', 'else', 'endif', 'error', 'if', 'ifdef',
  'ifndef', 'import', 'include', 'line', 'pragma', 'undef',
  'using', 'warning'
})
local preproc = token('preprocessor',
  #P('#') * starts_line('#' * S('\t ')^0 * preproc_word *
  (nonnewline_esc^0 + S('\t ') * nonnewline_esc^0)))

-- keywords
local keyword = token('keyword', word_match(word_list{
  -- C
  'asm', 'auto', 'break', 'case', 'const', 'continue', 'default', 'do', 'else',
  'extern', 'false', 'for', 'goto', 'if', 'inline', 'register', 'return',
  'sizeof', 'static', 'switch', 'true', 'typedef', 'volatile', 'while',
  'restrict', '_Bool', '_Complex', '_Pragma', '_Imaginary',
  -- C++
  'catch', 'class', 'const_cast', 'delete', 'dynamic_cast', 'explicit',
  'export', 'friend', 'mutable', 'namespace', 'new', 'operator', 'private',
  'protected', 'public', 'signals', 'slots', 'reinterpret_cast',
  'static_assert', 'static_cast', 'template', 'this', 'throw', 'try', 'typeid',
  'typename', 'using', 'virtual'
}))

-- types
local type = token('type', word_match(word_list{
  'bool', 'char', 'double', 'enum', 'float', 'int', 'long', 'short', 'signed',
  'struct', 'union', 'unsigned', 'void'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('+-/*%<>!=^&|?~:;.()[]{}'))

function LoadTokens()
  local cpp = cpp
  add_token(cpp, 'whitespace', ws)
  add_token(cpp, 'keyword', keyword)
  add_token(cpp, 'type', type)
  add_token(cpp, 'identifier', identifier)
  add_token(cpp, 'string', string)
  add_token(cpp, 'comment', comment)
  add_token(cpp, 'number', number)
  add_token(cpp, 'preproc', preproc)
  add_token(cpp, 'operator', operator)
  add_token(cpp, 'any_char', any_char)
end
