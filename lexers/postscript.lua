-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Postscript LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', '%' * nonnewline^0)

-- strings
local arrow_string = delimited_range('<>', '\\', true)
local nested_string = delimited_range('()', '\\', true, true)
local string = token('string', arrow_string + nested_string)

-- numbers
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'pop', 'exch', 'dup', 'copy', 'roll', 'clear', 'count', 'mark', 'cleartomark',
  'counttomark', 'exec', 'if', 'ifelse', 'for', 'repeat', 'loop', 'exit',
  'stop', 'stopped', 'countexecstack', 'execstack', 'quit', 'start',
  'true', 'false', 'NULL'
}))

-- functions
local func = token('function', word_match(word_list{
  'add', 'div', 'idiv', 'mod', 'mul', 'sub', 'abs', 'ned', 'ceiling', 'floor',
  'round', 'truncate', 'sqrt', 'atan', 'cos', 'sin', 'exp', 'ln', 'log', 'rand',
  'srand', 'rrand'
}))

-- identifiers
local word = (alpha + '-') * (alnum + '-')^0
local identifier = token('identifier', word)

-- labels
local label = token('label', '/' * word)

-- operators
local operator = token('operator', S('[]{}'))

function LoadTokens()
  local ps = postscript
  add_token(ps, 'whitespace', ws)
  add_token(ps, 'comment', comment)
  add_token(ps, 'string', string)
  add_token(ps, 'number', number)
  add_token(ps, 'keyword', keyword)
  add_token(ps, 'function', func)
  add_token(ps, 'identifier', identifier)
  add_token(ps, 'label', label)
  add_token(ps, 'operator', operator)
  add_token(ps, 'any_char', any_char)
end

function LoadStyles()
  add_style('label', style_variable)
end
