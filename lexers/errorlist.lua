-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Errorlist LPeg Lexer

module(..., package.seeall)
local P, S = lpeg.P, lpeg.S

local ws = token('whitespace', space^1)

local function line_match(pattern)
  return P(function(input, idx)
      if input:find(pattern) then return idx + #input end
    end)
end

-- command or return status
local cmd = token('command', line_match('^>.*$'))

-- <file>:<line>:<message>
local generic = token('generic_error', line_match('^.-:%d+:.*$'))

function LoadTokens()
  add_token(errorlist, 'whitespace', ws)
  add_token(errorlist, 'command', cmd)
  add_token(errorlist, 'generic_error', generic)
  add_token(errorlist, 'any_line', P(1)^1)
end

function LoadStyles()
  add_style('command', style_nothing)
  add_style('generic_error', style_error)
end

LexByLine = true
