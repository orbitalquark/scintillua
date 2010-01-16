-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- AWK LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', '#' * nonnewline^0)

-- strings
local sq_str = delimited_range("'", '\\', true, false, '\n')
local dq_str = delimited_range('"', '\\', true, false, '\n')
local regex = delimited_range('//', '\\', false, false, '\n')
local string = token('string', sq_str + dq_str + regex)

-- numbers
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'break', 'continue', 'do', 'delete', 'else', 'exit', 'for', 'function',
  'getline', 'if', 'next', 'nextfile', 'print', 'printf', 'return', 'while'
}))

-- functions
local func = token('function', word_match(word_list{
  'atan2', 'cos', 'exp', 'gensub', 'getline', 'gsub', 'index', 'int', 'length',
  'log', 'match', 'rand', 'sin', 'split', 'sprintf', 'sqrt', 'srand', 'sub',
  'substr', 'system', 'tolower', 'toupper',
}))

-- constants
local constant = token('constant', word_match(word_list{
  'BEGIN', 'END', 'ARGC', 'ARGIND', 'ARGV', 'CONVFMT', 'ENVIRON', 'ERRNO',
  'FIELDSWIDTH', 'FILENAME', 'FNR', 'FS', 'IGNORECASE', 'NF', 'NR', 'OFMT',
  'OFS', 'ORS', 'RLENGTH', 'RS', 'RSTART', 'RT', 'SUBSEP',
}))

-- identifiers
local identifier = token('identifier', word)

-- variables
local variable = token('variable', '$' * digit^1)

-- operators
local operator = token('operator', S('=!<>+-/*%&|^~,:;()[]{}'))

function LoadTokens()
  local awk = awk
  add_token(awk, 'whitespace', ws)
  add_token(awk, 'keyword', keyword)
  add_token(awk, 'function', func)
  add_token(awk, 'constant', constant)
  add_token(awk, 'identifier', identifier)
  add_token(awk, 'string', string)
  add_token(awk, 'comment', comment)
  add_token(awk, 'number', number)
  add_token(awk, 'variable', variable)
  add_token(awk, 'operator', operator)
  add_token(awk, 'any_char', any_char)
end
