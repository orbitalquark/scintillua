-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Forth LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token(l.WHITESPACE, l.space^1)

-- comments
local line_comment = S('|\\') * l.nonnewline^0
local block_comment = '(*' * (l.any - '*)')^0 * P('*)')^-1
local comment = token(l.COMMENT, line_comment + block_comment)

-- strings
local s_str = 's' * l.delimited_range('"', nil, true, false, '\n')
local dot_str = '.' * l.delimited_range('"', nil, true, false, '\n')
local f_str = 'f' * l.delimited_range('"', nil, true, false, '\n')
local dq_str = l.delimited_range('"', nil, true, false, '\n')
local string = token(l.STRING, s_str + dot_str + f_str + dq_str)

-- numbers
local number = token(l.NUMBER, P('-')^-1 * l.digit^1 * (S('./') * l.digit^1)^-1)

-- keywords
local keyword = token(l.KEYWORD, word_match({
  'swap', 'drop', 'dup', 'nip', 'over', 'rot', '-rot', '2dup', '2drop', '2over',
  '2swap', '>r', 'r>',
  'and', 'or', 'xor', '>>', '<<', 'not', 'negate', 'mod', '/mod', '1+', '1-',
  'base', 'hex', 'decimal', 'binary', 'octal',
  '@', '!', 'c@', 'c!', '+!', 'cell+', 'cells', 'char+', 'chars',
  'create', 'does>', 'variable', 'variable,', 'literal', 'last', '1,', '2,',
  '3,', ',', 'here', 'allot', 'parse', 'find', 'compile',
  -- operators
  'if', '=if', '<if', '>if', '<>if', 'then', 'repeat', 'until', 'forth', 'macro'
}, '2><1-@!+3,='))

-- identifiers
local word = (l.alnum + S('+-*=<>.?/\'%,_$'))^1
local identifier = token(l.IDENTIFIER, word)

-- operators
local operator = token(l.OPERATOR, S(':;<>+*-/()[]'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'string', string },
  { 'identifier', identifier },
  { 'comment', comment },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
