-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Java LPeg Lexer

-- Modified by Brian Schott

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token(l.WHITESPACE, l.space^1)

-- comments
local line_comment = '//' * l.nonnewline_esc^0
local block_comment = '/*' * (l.any - '*/')^0 * P('*/')^-1
local comment = token(l.COMMENT, line_comment + block_comment)

-- strings
local sq_str = l.delimited_range("'", '\\', true, false, '\n')
local dq_str = l.delimited_range('"', '\\', true, false, '\n')
local string = token(l.STRING, sq_str + dq_str)

-- numbers
local number = token(l.NUMBER, (l.float + l.integer) * S('LlFfDd')^-1)

-- keywords
local keyword = token(l.KEYWORD, word_match {
  'abstract', 'assert', 'break', 'case', 'catch', 'class', 'const', 'continue',
  'default', 'do', 'else', 'enum', 'extends', 'final', 'finally', 'for',
  'future', 'generic', 'goto', 'if', 'implements', 'import', 'inner',
  'instanceof', 'interface', 'native', 'new', 'null', 'outer', 'package',
  'private', 'protected', 'public', 'rest', 'return', 'static', 'super',
  'switch', 'synchronized', 'this', 'throw', 'throws', 'transient', 'try',
  'var', 'while', 'volatile', 'true', 'false'
})

-- types
local type = token(l.TYPE, word_match {
  'boolean', 'byte', 'char', 'double', 'float', 'int', 'long', 'short', 'void'
})

-- identifiers
local identifier = token(l.IDENTIFIER, l.word)

-- annotations
local annotation = token('annotation', '@' * l.word)

local func = token(l.FUNCTION, l.word) * #P('(')

local class_sequence = token(l.KEYWORD, P('class')) * ws^1 *
                       token(l.CLASS, l.word)

-- operators
local operator = token(l.OPERATOR, S('+-/*%<>!=^&|?~:;.()[]{}'))

_rules = {
  { 'whitespace', ws },
  { 'class', class_sequence },
  { 'keyword', keyword },
  { 'type', type },
  { 'function', func},
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'annotation', annotation },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

_tokenstyles = {
  { 'annotation', l.style_preproc },
}
