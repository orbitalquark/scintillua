-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Gap LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', '#' * nonnewline^0)

-- strings
local sq_str = delimited_range("'", '\\', true, false, '\n')
local dq_str = delimited_range('"', '\\', true, false, '\n')
local string = token('string', sq_str + dq_str)

-- numbers
local number = token('number', digit^1 * -alpha)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'and', 'break', 'continue', 'do', 'elif', 'else', 'end', 'fail', 'false',
  'fi', 'for', 'function', 'if', 'in', 'infinity', 'local', 'not', 'od', 'or',
  'rec', 'repeat', 'return', 'then', 'true', 'until', 'while'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('*+-,./:;<=>~^#()[]{}'))

function LoadTokens()
  local gap = gap
  add_token(gap, 'whitespace', ws)
  add_token(gap, 'comment', comment)
  add_token(gap, 'string', string)
  add_token(gap, 'number', number)
  add_token(gap, 'keyword', keyword)
  add_token(gap, 'identifier', identifier)
  add_token(gap, 'operator', operator)
  add_token(gap, 'any_char', any_char)
end
