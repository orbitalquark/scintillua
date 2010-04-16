-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Haskell LPeg Lexer
-- Modified by Alex Suraci

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local line_comment = '--' * l.nonnewline_esc^0
local block_comment = '{-' * (l.any - '-}')^0 * P('-}')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local string = token('string', l.delimited_range('"', '\\'))

-- chars
local char = token('char', l.delimited_range("'", "\\", false, false, '\n'))

-- numbers
local number = token('number', l.float + l.integer)

-- keywords
local keyword = token('keyword', word_match {
  'case', 'class', 'data', 'default', 'deriving', 'do', 'else', 'if', 'import',
  'in', 'infix', 'infixl', 'infixr', 'instance', 'let', 'module', 'newtype',
  'of', 'then', 'type', 'where', '_', 'as', 'qualified', 'hiding'
})

-- operators
local op = l.punct - S('()[]{}')
local operator = token('operator', op)

-- identifiers
local word = (l.alnum + S("._'#"))^0
local identifier = token('identifier', (l.alpha + '_') * word)

-- types & type constructors
local constructor = token('type', (l.upper * word) + (P(":") * (op^1 - P(":"))))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'type', constructor },
  { 'identifier', identifier },
  { 'string', string },
  { 'char', char },
  { 'comment', comment },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
