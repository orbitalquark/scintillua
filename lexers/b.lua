-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- B LPeg Lexer

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

-- keywords
local keyword = token('keyword', word_match(word_list{
  -- clauses
  'ABSTRACT_CONSTANTS', 'ABSTRACT_VARIABLES', 'CONCRETE_CONSTANTS',
  'CONCRETE_VARIABLES', 'CONSTANTS', 'VARIABLES', 'ASSERTIONS', 'CONSTRAINTS',
  'DEFINITIONS', 'EXTENDS', 'IMPLEMENTATION', 'IMPORTS', 'INCLUDES',
  'INITIALISATION', 'INVARIANT', 'LOCAL_OPERATIONS', 'MACHINE', 'OPERATIONS',
  'PROMOTES', 'PROPERTIES', 'REFINES', 'REFINEMENT', 'SEES', 'SETS', 'USES',
  'VALUES',
  -- substitutions
  'ANY', 'ASSERT', 'BE', 'BEGIN', 'CASE', 'CHOICE', 'DO', 'EITHER', 'ELSE',
  'ELSIF', 'END', 'IF', 'IN', 'LET', 'OF', 'OR', 'PRE', 'SELECT', 'THEN', 'VAR',
  'VARIANT', 'WHEN', 'WHERE', 'WHILE'
}))

-- types
local type = token('type', word_match(word_list{
  'FIN', 'FIN1', 'INT', 'INTEGER', 'INTER', 'MAXINT', 'MININT', 'NAT', 'NAT1',
  'NATURAL', 'NATURAL1', 'PI', 'POW', 'POW1', 'SIGMA', 'UNION'
}))

-- functions
local func = token('function', word_match(word_list{
  'arity', 'bin', 'bool', 'btree', 'card', 'closure', 'closure1', 'conc',
  'const', 'dom', 'father', 'first', 'fnc', 'front', 'id', 'infix', 'inter',
  'iseq', 'iseq1', 'iterate', 'last', 'left', 'max', 'min', 'mirror', 'mod',
  'not', 'or', 'perm', 'postfix', 'pred', 'prefix', 'prj1', 'prj2', 'r~', 'ran',
  'rank', 'rec', 'rel', 'rev', 'right', 'seq', 'seq1', 'size', 'sizet', 'skip',
  'son', 'sons', 'struct', 'subtree', 'succ', 'tail', 'top', 'tree', 'union'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('!#%=&<>*+/\\~:;|-^.,()[]{}') + '$0')

function LoadTokens()
  local b = b
  add_token(b, 'whitespace', ws)
  add_token(b, 'comment', comment)
  add_token(b, 'string', string)
  add_token(b, 'number', number)
  add_token(b, 'keyword', keyword)
  add_token(b, 'type', type)
  add_token(b, 'function', func)
  add_token(b, 'identifier', identifier)
  add_token(b, 'operator', operator)
  add_token(b, 'any_char', any_char)
end
