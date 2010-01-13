-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Diff LPeg Lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- If the pattern matches the start of a line, match the entire line.
local function line_match(pattern)
  return P(function(input, idx)
      if input:match(pattern, idx) then return #input end
    end)
end

-- text, separators, file headers
local text = token('comment', line_match('^Index: .*$'))
local separator = token('separator', ('---' + P('*')^4 + P('=')^1)) * ws^0 * P(-1)
local header_file = token('header_file', (P('*** ') + '--- ' + '+++ ') * any^1)

-- positions
local number_range = digit^1 * (',' * digit^1)^-1
local normal_pos = number_range * S('adc') * number_range
local context_pos = '*** ' * number_range * ' ****' +
  '--- ' * number_range * ' ----'
local unified_pos = P('@@ ') * '-' * number_range * ' +' * number_range * ' @@'
local position = token('position', normal_pos + context_pos + unified_pos) * any^0 * P(-1)

-- additions, deletions, changes
local addition = token('addition', line_match('^[>+].*$'))
local deletion = token('deletion', line_match('^[<-].*$'))
local change   = token('change', line_match('^! .*$'))

function LoadTokens()
  add_token(diff, 'whitespace', ws)
  add_token(diff, 'text', text)
  add_token(diff, 'separator', separator)
  add_token(diff, 'header_file', header_file)
  add_token(diff, 'position', position)
  add_token(diff, 'addition', addition)
  add_token(diff, 'deletion', deletion)
  add_token(diff, 'change', change)
  add_token(diff, 'any_line', token('default', any^1))
end

function LoadStyles()
  add_style('separator', style_comment)
  add_style('header_file', style_nothing..{ bold = true })
  add_style('position', style_number)
  add_style('addition', style_nothing..{ back = colors.green, eolfilled = true })
  add_style('deletion', style_nothing..{ back = colors.red, eolfilled = true })
  add_style('change', style_nothing..{ back = colors.yellow, eolfilled = true })
end

LexByLine = true
