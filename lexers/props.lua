-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Props LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', #P('#') * starts_line('#' * nonnewline^0))

-- equals
local equals = token('operator', '=')

-- strings
local sq_str = delimited_range("'", '\\', true)
local dq_str = delimited_range('"', '\\', true)
local string = token('string', sq_str + dq_str)

-- variables
local variable = token('variable', '$(' * (any - ')')^1 * ')')

-- colors
local color = token('color', '#' * xdigit * xdigit * xdigit * xdigit * xdigit * xdigit)

function LoadTokens()
  local props = props
  add_token(props, 'whitespace', ws)
  add_token(props, 'comment', comment)
  add_token(props, 'equals', equals)
  add_token(props, 'string', string)
  add_token(props, 'variable', variable)
  add_token(props, 'color', color)
  add_token(props, 'any_char', any_char)
end

function LoadStyles()
  add_style('variable', style_keyword)
  add_style('color', style_number)
end

-- line by line lexer
LexByLine = true
