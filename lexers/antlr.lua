-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- ANTLR LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token(l.WHITESPACE, l.space^1)

-- comments
local line_comment = '//' * l.nonnewline^0;
local block_comment = '/*' * (l.any - '*/')^0 * P('*/')^-1
local comment = token(l.COMMENT, line_comment + block_comment)

-- strings
local string = token(l.STRING, l.delimited_range("'", '\\', true, false, '\n'))

-- keywords
local keyword = token(l.KEYWORD, word_match {
  'abstract', 'break', 'case', 'catch', 'continue', 'default', 'do', 'else',
  'extends', 'final', 'finally', 'for', 'if', 'implements', 'instanceof',
  'native', 'new', 'private', 'protected', 'public', 'return', 'static',
  'switch', 'synchronized', 'throw', 'throws', 'transient', 'try', 'volatile',
  'while', 'package', 'import', 'header', 'options', 'tokens', 'strictfp',
  'false', 'null', 'super', 'this', 'true'
})

-- types
local type = token(l.TYPE, word_match {
  'boolean', 'byte', 'char', 'class', 'double', 'float', 'int', 'interface',
  'long', 'short', 'void'
})

-- functions
local func = token(l.FUNCTION, 'assert')

-- identifiers
local identifier = token(l.IDENTIFIER, l.word)

-- operators
local operator = token(l.OPERATOR, S('$@:;|.=+*?~!^>-()[]{}'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'type', type },
  { 'function', func },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
