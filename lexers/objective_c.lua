-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Objective C LPeg Lexer

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
  'warning'
})
local preproc = token('preprocessor',
  #P('#') * starts_line('#' * S('\t ')^0 * preproc_word *
  (nonnewline_esc^1 + space * nonnewline_esc^0)))

-- keywords
local keyword = token('keyword', word_match(word_list{
  -- from C
  'asm', 'auto', 'break', 'case', 'const', 'continue', 'default', 'do', 'else',
  'extern', 'false', 'for', 'goto', 'if', 'inline', 'register', 'return',
  'sizeof', 'static', 'switch', 'true', 'typedef', 'void', 'volatile', 'while',
  'restrict', '_Bool', '_Complex', '_Pragma', '_Imaginary',
  -- objective C
  'oneway', 'in', 'out', 'inout', 'bycopy', 'byref', 'self', 'super',
  -- preprocessor directives
  '@interface', '@implementation', '@protocol', '@end', '@private',
  '@protected', '@public', '@class', '@selector', '@encode', '@defs',
  '@synchronized', '@try', '@throw', '@catch', '@finally',
  -- constants
  'TRUE', 'FALSE', 'YES', 'NO', 'NULL', 'nil', 'Nil', 'METHOD_NULL'
}, '@'))

-- types
local type = token('type', word_match(word_list{
  'apply_t', 'id', 'Class', 'MetaClass', 'Object', 'Protocol', 'retval_t',
  'SEL', 'STR', 'IMP', 'BOOL', 'TypedStream'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('+-/*%<>!=^&|?~:;.()[]{}'))

function LoadTokens()
  local objc = objective_c
  add_token(objc, 'whitespace', ws)
  add_token(objc, 'keyword', keyword)
  add_token(objc, 'type', type)
  add_token(objc, 'identifier', identifier)
  add_token(objc, 'string', string)
  add_token(objc, 'comment', comment)
  add_token(objc, 'number', number)
  add_token(objc, 'preproc', preproc)
  add_token(objc, 'operator', operator)
  add_token(objc, 'any_char', any_char)
end
