-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Forth LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = S('|\\') * nonnewline^0
local block_comment = '(*' * (any - '*)')^0 * P('*)')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local s_str = 's' * delimited_range('"', nil, true, false, '\n')
local dot_str = '.' * delimited_range('"', nil, true, false, '\n')
local f_str = 'f' * delimited_range('"', nil, true, false, '\n')
local dq_str = delimited_range('"', nil, true, false, '\n')
local string = token('string', s_str + dot_str + f_str + dq_str)

-- numbers
local number = token('number', P('-')^-1 * digit^1 * (S('./') * digit^1)^-1)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'swap', 'drop', 'dup', 'nip', 'over', 'rot', '-rot', '2dup', '2drop', '2over',
  '2swap', '>r', 'r>',
  'and', 'or', 'xor', '>>', '<<', 'not', 'negate', 'mod', '/mod', '1+', '1-',
  'base', 'hex', 'decimal', 'binary', 'octal',
  '@', '!', 'c@', 'c!', '+!', 'cell+', 'cells', 'char+', 'chars',
  'create', 'does&gt;', 'variable', 'variable,', 'literal', 'last', '1,', '2,',
  '3,', ',', 'here', 'allot', 'parse', 'find', 'compile',
  -- operators
  'if', '=if', '<if', '>if', '<>if', 'then', 'repeat', 'until', 'forth', 'macro'
}, '2><1-@!+3,='))

-- identifiers
local word = (alnum + S('+-*=<>.?/\'%,_$'))^1
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S(':;<>+*-/()[]'))

function LoadTokens()
  local forth = forth
  add_token(forth, 'whitespace', ws)
  add_token(forth, 'comment', comment)
  add_token(forth, 'string', string)
  add_token(forth, 'number', number)
  add_token(forth, 'keyword', keyword)
  add_token(forth, 'identifier', identifier)
  add_token(forth, 'operator', operator)
  add_token(forth, 'any_char', any_char)
end
