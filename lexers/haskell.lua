-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Haskell LPeg Lexer
-- Modified by Alex Suraci

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = '--' * nonnewline_esc^0
local block_comment = '{-' * (any - '-}')^0 * P('-}')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local string = token('string', delimited_range('"', '\\'))

-- chars
local char = token('char', delimited_range("'", "\\", false, false, '\n'))

-- numbers
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'case', 'class', 'data', 'default', 'deriving', 'do', 'else', 'if', 'import',
  'in', 'infix', 'infixl', 'infixr', 'instance', 'let', 'module', 'newtype',
  'of', 'then', 'type', 'where', '_', 'as', 'qualified', 'hiding'
}))

-- operators
local op = punct - S('()[]{}')
local operator = token('operator', op)

-- identifiers
local word = (alnum + S("._'#"))^0
local identifier = token('identifier', (alpha + '_') * word)

-- types & type constructors
local constructor = token('type', (upper * word) + (P(":") * (op^1 - P(":"))))

function LoadTokens()
  local haskell = haskell
  add_token(haskell, 'whitespace', ws)
  add_token(haskell, 'keyword', keyword)
  add_token(haskell, 'type', constructor)
  add_token(haskell, 'identifier', identifier)
  add_token(haskell, 'string', string)
  add_token(haskell, 'char', char)
  add_token(haskell, 'comment', comment)
  add_token(haskell, 'number', number)
  add_token(haskell, 'operator', operator)
  add_token(haskell, 'any_char', any_char)
end
