-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- AWK LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token(l.WHITESPACE, l.space^1)

-- comments
local comment = token(l.COMMENT, '#' * l.nonnewline^0)

-- strings
local sq_str = l.delimited_range("'", '\\', true, false, '\n')
local dq_str = l.delimited_range('"', '\\', true, false, '\n')
local regex = l.delimited_range('//', '\\', false, false, '\n')
local string = token(l.STRING, sq_str + dq_str + regex)

-- numbers
local number = token(l.NUMBER, l.float + l.integer)

-- keywords
local keyword = token(l.KEYWORD, word_match {
  'break', 'continue', 'do', 'delete', 'else', 'exit', 'for', 'function',
  'getline', 'if', 'next', 'nextfile', 'print', 'printf', 'return', 'while'
})

-- functions
local func = token(l.FUNCTION, word_match {
  'atan2', 'cos', 'exp', 'gensub', 'getline', 'gsub', 'index', 'int', 'length',
  'log', 'match', 'rand', 'sin', 'split', 'sprintf', 'sqrt', 'srand', 'sub',
  'substr', 'system', 'tolower', 'toupper',
})

-- constants
local constant = token(l.CONSTANT, word_match {
  'BEGIN', 'END', 'ARGC', 'ARGIND', 'ARGV', 'CONVFMT', 'ENVIRON', 'ERRNO',
  'FIELDSWIDTH', 'FILENAME', 'FNR', 'FS', 'IGNORECASE', 'NF', 'NR', 'OFMT',
  'OFS', 'ORS', 'RLENGTH', 'RS', 'RSTART', 'RT', 'SUBSEP',
})

-- identifiers
local identifier = token(l.IDENTIFIER, l.word)

-- variables
local variable = token(l.VARIABLE, '$' * l.digit^1)

-- operators
local operator = token(l.OPERATOR, S('=!<>+-/*%&|^~,:;()[]{}'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'function', func },
  { 'constant', constant },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'variable', variable },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
