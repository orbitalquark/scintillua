-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Haskell LPeg Lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = '--' * nonnewline_esc^0
local block_comment = '{-' * (any - '-}')^0 * P('-}')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local sq_str = delimited_range("'", nil, true, false, '\n')
local dq_str = delimited_range('"', '\\', true)
local string = token('string', sq_str + dq_str)

-- numbers
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'case', 'class', 'data', 'default', 'deriving', 'do', 'else', 'if', 'import',
  'in', 'infix', 'infixl', 'infixr', 'instance', 'let', 'module', 'newtype',
  'of', 'then', 'type', 'where', '_', 'as', 'qualified', 'hiding',
  'EQ', 'False', 'GT', 'Just', 'LT', 'Left', 'Nothing', 'Right', 'True',
  -- operators
  'quot', 'rem', 'div', 'mod', 'elem', 'notElem', 'seq'
}))

-- types
local type = token('type', word_match(word_list{
  'Addr', 'Bool', 'Bounded', 'Char', 'Double', 'Either', 'Enum', 'Eq',
  'FilePath', 'Float', 'Floating', 'Fractional', 'Functor', 'IO', 'IOError',
  'IOResult', 'Int', 'Integer', 'Integral', 'Ix', 'Maybe', 'Monad', 'Num',
  'Ord', 'Ordering', 'Ratio', 'Rational', 'Read', 'ReadS', 'Real', 'RealFloat',
  'RealFrac', 'Show', 'ShowS', 'String'
}))

-- identifiers
local word = (alpha + '_') * (alnum + S("._'#"))^0
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('.&:<>+-*/%^=|@~!$()[]{}'))

function LoadTokens()
  local haskell = haskell
  add_token(haskell, 'whitespace', ws)
  add_token(haskell, 'comment', comment)
  add_token(haskell, 'string', string)
  add_token(haskell, 'number', number)
  add_token(haskell, 'keyword', keyword)
  add_token(haskell, 'type', type)
  add_token(haskell, 'identifier', identifier)
  add_token(haskell, 'operator', operator)
  add_token(haskell, 'any_char', any_char)
end
