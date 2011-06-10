-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Gap LPeg lexer

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
local string = token(l.STRING, sq_str + dq_str)

-- numbers
local number = token(l.NUMBER, l.digit^1 * -l.alpha)

-- keywords
local keyword = token(l.KEYWORD, word_match {
  'and', 'break', 'continue', 'do', 'elif', 'else', 'end', 'fail', 'false',
  'fi', 'for', 'function', 'if', 'in', 'infinity', 'local', 'not', 'od', 'or',
  'rec', 'repeat', 'return', 'then', 'true', 'until', 'while'
})

-- identifiers
local identifier = token(l.IDENTIFIER, l.word)

-- operators
local operator = token(l.OPERATOR, S('*+-,./:;<=>~^#()[]{}'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

_foldsymbols = {
  _patterns = { '[a-z]+' },
  keyword = {
    ['function'] = 1, ['do'] = 1, ['if'] = 1, ['repeat'] = 1,
    ['end'] = -1, od = -1, fi = -1, ['until'] = -1
  }
}
