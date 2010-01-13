-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Ini LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', #S(';#') * starts_line(S(';#') * nonnewline^0))

-- strings
local sq_str = delimited_range("'", '\\', true)
local dq_str = delimited_range('"', '\\', true)
local label = delimited_range('[]', nil, true, false, '\n')
local string = token('string', sq_str + dq_str + label)

-- numbers
local dec = digit^1 * ('_' * digit^1)^0
local oct_num = '0' * S('01234567_')^1
local integer = S('+-')^-1 * (hex_num + oct_num + dec)
local number = token('number', (float + integer))

-- keywords
local keyword = token('keyword', word_match(word_list{
  'true', 'false', 'on', 'off', 'yes', 'no'
}))

-- identifiers
local word = (alpha + '_') * (alnum + S('_.'))^0
local identifier = token('identifier', word)

-- operators
local operator = token('operator', '=')

function LoadTokens()
  local ini = ini
  add_token(ini, 'whitespace', ws)
  add_token(ini, 'comment', comment)
  add_token(ini, 'string', string)
  add_token(ini, 'number', number)
  add_token(ini, 'keyword', keyword)
  add_token(ini, 'identifier', identifier)
  add_token(ini, 'operator', operator)
  add_token(ini, 'any_char', any_char)
end

-- line by line lexer
LexByLine = true
