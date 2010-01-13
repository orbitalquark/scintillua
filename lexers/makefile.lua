-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Makefile LPeg Lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

local assign = token('operator', P(':')^-1 * '=')
local colon = token('operator', ':') * -P('=')

-- comments
local comment = token('comment', '#' * nonnewline^0)

-- preprocessor
local preproc = token('preprocessor', '!' * nonnewline^0)

-- targets
local target = token('target', (any - ':')^1) * colon * (ws * nonnewline^0)^-1

-- commands
local command = #P('\t') * token('command', nonnewline^1)

-- lines
local var_char = any - space - S(':#=')
local identifier = token('identifier', var_char^1) * ws^0 * assign
local macro = token('macro', '$' * (delimited_range('()', nil, nil, true) + S('<@')))
local regular_line = ws + identifier + macro + comment + any_char

function LoadTokens()
  local makefile = makefile
  add_token(makefile, 'comment', comment)
  add_token(makefile, 'preprocessor', preproc)
  add_token(makefile, 'target', target)
  add_token(makefile, 'command', command)
  add_token(makefile, 'whitespace', ws)
  add_token(makefile, 'line', regular_line)
end

function LoadStyles()
  add_style('target', style_definition)
  add_style('command', style_string)
  add_style('identifier', style_nothing..{ bold = true })
  add_style('macro', style_keyword)
end

LexByLine = true
