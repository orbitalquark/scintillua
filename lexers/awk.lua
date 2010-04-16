-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- AWK LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local comment = token('comment', '#' * l.nonnewline^0)

-- strings
local sq_str = l.delimited_range("'", '\\', true, false, '\n')
local dq_str = l.delimited_range('"', '\\', true, false, '\n')
local regex = l.delimited_range('//', '\\', false, false, '\n')
local string = token('string', sq_str + dq_str + regex)

-- numbers
local number = token('number', l.float + l.integer)

-- keywords
local keyword = token('keyword', word_match {
  'break', 'continue', 'do', 'delete', 'else', 'exit', 'for', 'function',
  'getline', 'if', 'next', 'nextfile', 'print', 'printf', 'return', 'while'
})

-- functions
local func = token('function', word_match {
  'atan2', 'cos', 'exp', 'gensub', 'getline', 'gsub', 'index', 'int', 'length',
  'log', 'match', 'rand', 'sin', 'split', 'sprintf', 'sqrt', 'srand', 'sub',
  'substr', 'system', 'tolower', 'toupper',
})

-- constants
local constant = token('constant', word_match {
  'BEGIN', 'END', 'ARGC', 'ARGIND', 'ARGV', 'CONVFMT', 'ENVIRON', 'ERRNO',
  'FIELDSWIDTH', 'FILENAME', 'FNR', 'FS', 'IGNORECASE', 'NF', 'NR', 'OFMT',
  'OFS', 'ORS', 'RLENGTH', 'RS', 'RSTART', 'RT', 'SUBSEP',
})

-- identifiers
local identifier = token('identifier', l.word)

-- variables
local variable = token('variable', '$' * l.digit^1)

-- operators
local operator = token('operator', S('=!<>+-/*%&|^~,:;()[]{}'))

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
