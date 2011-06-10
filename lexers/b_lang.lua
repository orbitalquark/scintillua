-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- B LPeg Lexer

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
local number = token(l.NUMBER, l.float + l.integer)

-- keywords
local keyword = token(l.KEYWORD, word_match {
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
})

-- types
local type = token(l.TYPE, word_match {
  'FIN', 'FIN1', 'INT', 'INTEGER', 'INTER', 'MAXINT', 'MININT', 'NAT', 'NAT1',
  'NATURAL', 'NATURAL1', 'PI', 'POW', 'POW1', 'SIGMA', 'UNION'
})

-- functions
local func = token(l.FUNCTION, word_match {
  'arity', 'bin', 'bool', 'btree', 'card', 'closure', 'closure1', 'conc',
  'const', 'dom', 'father', 'first', 'fnc', 'front', 'id', 'infix', 'inter',
  'iseq', 'iseq1', 'iterate', 'last', 'left', 'max', 'min', 'mirror', 'mod',
  'not', 'or', 'perm', 'postfix', 'pred', 'prefix', 'prj1', 'prj2', 'r~', 'ran',
  'rank', 'rec', 'rel', 'rev', 'right', 'seq', 'seq1', 'size', 'sizet', 'skip',
  'son', 'sons', 'struct', 'subtree', 'succ', 'tail', 'top', 'tree', 'union'
})

-- identifiers
local identifier = token(l.IDENTIFIER, l.word)

-- operators
local operator = token(l.OPERATOR, S('!#%=&<>*+/\\~:;|-^.,()[]{}') + '$0')

_rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'string', string },
  { 'number', number },
  { 'keyword', keyword },
  { 'type', type },
  { 'function', func },
  { 'identifier', identifier },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

_foldsymbols = {
  _patterns = { '[{}]', '/%*', '%*/' },
  comment = { ['/*'] = 1, ['*/'] = -1 },
  operator = { ['{'] = 1, ['}'] = -1 }
}
