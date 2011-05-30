-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- CoffeeScript LPeg Lexer

local l = lexer
local token, word_match = l.token, l.word_match
local P, S = l.lpeg.P, l.lpeg.S

module(...)

local ws = token(l.WHITESPACE, l.space^1)

-- comments
local line_comment = '#' * l.nonnewline_esc^0
local comment = token(l.COMMENT, line_comment)

-- strings
local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local regex_str = l.delimited_range('/', '\\', nil, nil, '\n') * S('igm')^0
local string = token(l.STRING, sq_str + dq_str) + P(function(input, index)
  if index == 1 then return index end
  local i = index
  while input:sub(i - 1, i - 1):match('[ \t\r\n\f]') do i = i - 1 end
  return input:sub(i - 1, i - 1):match('[+%-*%%^!=&|?:;,()%[%]{}]') and index
end) * token('regex', regex_str)

-- numbers
local number = token(l.NUMBER, l.float + l.integer)

-- keywords
local keyword = token(l.KEYWORD, word_match {
  'all', 'and', 'bind', 'break', 'by', 'case', 'catch', 'class', 'const',
  'continue', 'default', 'delete', 'do', 'each', 'else', 'enum', 'export',
  'extends', 'false', 'for', 'finally', 'function', 'if', 'import', 'in',
  'instanceof', 'is', 'isnt', 'let', 'loop', 'native', 'new', 'no', 'not', 'of',
  'off', 'on', 'or', 'return', 'super', 'switch', 'then', 'this', 'throw',
  'true', 'try', 'typeof', 'unless', 'until', 'var', 'void', 'with', 'when',
  'while', 'yes'
})

-- identifiers
local identifier = token(l.IDENTIFIER, l.word)

-- operators
local operator = token(l.OPERATOR, S('+-/*%<>!=^&|?~:;.()[]{}'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'identifier', identifier },
  { 'comment', comment },
  { 'number', number },
  { 'string', string },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

_tokenstyles = {
  { 'regex', l.style_string..{ back = l.color('44', '44', '44')} },
}
