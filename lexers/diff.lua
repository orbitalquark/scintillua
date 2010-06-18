-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Diff LPeg Lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- If the pattern matches the start of a line, match the entire line.
local function line_match(pattern)
  return P(function(input, idx)
      if input:match(pattern, idx) then return #input end
    end)
end

-- text, separators, file headers
local text = token('comment', line_match('^Index: .*$'))
local separator =
  token('separator', ('---' + P('*')^4 + P('=')^1)) * ws^0 * P(-1)
local header_file =
  token('header_file', (P('*** ') + '--- ' + '+++ ') * l.any^1)

-- positions
local number_range = l.digit^1 * (',' * l.digit^1)^-1
local normal_pos = number_range * S('adc') * number_range
local context_pos =
  '*** ' * number_range * ' ****' + '--- ' * number_range * ' ----'
local unified_pos = P('@@ ') * '-' * number_range * ' +' * number_range * ' @@'
local position =
  token('position', normal_pos + context_pos + unified_pos) * l.any^0 * P(-1)

-- additions, deletions, changes
local addition = token('addition', line_match('^[>+].*$'))
local deletion = token('deletion', line_match('^[<-].*$'))
local change   = token('change', line_match('^! .*$'))

_rules = {
  { 'whitespace', ws },
  { 'text', text },
  { 'separator', separator },
  { 'header_file', header_file },
  { 'position', position },
  { 'addition', addition },
  { 'deletion', deletion },
  { 'change', change },
  { 'any_line', token('default', l.any^1) },
}

_tokenstyles = {
  { 'separator', l.style_comment },
  { 'header_file', l.style_nothing..{ bold = true } },
  { 'position', l.style_number },
  { 'addition', l.style_nothing..{ back = l.colors.green, eolfilled = true } },
  { 'deletion', l.style_nothing..{ back = l.colors.red, eolfilled = true } },
  { 'change', l.style_nothing..{ back = l.colors.yellow, eolfilled = true } },
}

_LEXBYLINE = true
