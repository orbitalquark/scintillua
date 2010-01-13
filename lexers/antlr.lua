-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- ANTLR LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = '//' * nonnewline^0;
local block_comment = '/*' * (any - '*/')^0 * P('*/')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local string = token('string', delimited_range("'", '\\', true, false, '\n'))

-- keywords
local keyword = token('keyword', word_match(word_list{
  'abstract', 'break', 'case', 'catch', 'continue', 'default', 'do', 'else',
  'extends', 'final', 'finally', 'for', 'if', 'implements', 'instanceof',
  'native', 'new', 'private', 'protected', 'public', 'return', 'static',
  'switch', 'synchronized', 'throw', 'throws', 'transient', 'try', 'volatile',
  'while', 'package', 'import', 'header', 'options', 'tokens', 'strictfp',
  'false', 'null', 'super', 'this', 'true'
}))

-- types
local type = token('type', word_match(word_list{
  'boolean', 'byte', 'char', 'class', 'double', 'float', 'int', 'interface',
  'long', 'short', 'void'
}))

-- functions
local func = token('function', 'assert')

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('$@:;|.=+*?~!^>-()[]{}'))

function LoadTokens()
  local antlr = antlr
  add_token(antlr, 'whitespace', ws)
  add_token(antlr, 'comment', comment)
  add_token(antlr, 'string', string)
  add_token(antlr, 'keyword', keyword)
  add_token(antlr, 'type', type)
  add_token(antlr, 'function', func)
  add_token(antlr, 'identifier', identifier)
  add_token(antlr, 'operator', operator)
  add_token(antlr, 'any_char', any_char)
end
