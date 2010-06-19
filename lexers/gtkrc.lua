-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Gtkrc LPeg lexer

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
local string = token('string', sq_str + dq_str)

-- numbers
local number = token('number', l.digit^1 * ('.' * l.digit^1)^-1)

-- keywords
local keyword = token('keyword', word_match {
  'binding', 'class', 'include', 'module_path', 'pixmap_path', 'im_module_file',
  'style', 'widget', 'widget_class'
})

-- variables
local variable = token('variable', word_match {
  'bg', 'fg', 'base', 'text', 'xthickness', 'ythickness', 'bg_pixmap', 'font',
  'fontset', 'font_name', 'stock', 'color', 'engine'
})

-- states
local state = token('constant', word_match {
  'ACTIVE', 'SELECTED', 'NORMAL', 'PRELIGHT', 'INSENSITIVE', 'TRUE', 'FALSE'
})

-- functions
local func = token('function', word_match {
  'mix', 'shade', 'lighter', 'darker'
})

-- identifiers
local identifier = token('identifier', l.alpha * (l.alnum + S('_-'))^0)

-- operators
local operator = token('operator', S(':=,*()[]{}'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'variable', variable },
  { 'state', state },
  { 'function', func },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
