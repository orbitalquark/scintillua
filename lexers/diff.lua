-- Copyright 2006-2013 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Diff LPeg lexer.

local l, token, word_match = lexer, lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = {_NAME = 'diff'}

-- Text, separators, and file headers.
local index = token(l.COMMENT, 'Index: ' * l.any^0 * P(-1))
local separator = token(l.COMMENT, ('---' + P('*')^4 + P('=')^1) * l.space^0 *
                                   P(-1))
local header = token('header', (P('*** ') + '--- ' + '+++ ') * l.any^1 * P(-1))

-- Location.
local location = token(l.NUMBER, ('@@' + l.digit^1 + '****') * l.any^1 * P(-1))

-- Additions, deletions, and changes.
local addition = token('addition', S('>+') * l.any^0 * P(-1))
local deletion = token('deletion', S('<-') * l.any^0 * P(-1))
local change   = token('change', '! ' * l.any^0 * P(-1))

M._rules = {
  {'index', index},
  {'separator', separator},
  {'header', header},
  {'location', location},
  {'addition', addition},
  {'deletion', deletion},
  {'change', change},
  {'any_line', token('default', l.any^1)},
}

M._tokenstyles = {
  header = l.STYLE_COMMENT,
  addition = 'fore:$(color.green)',
  deletion = 'fore:$(color.red)',
  change = 'fore:$(color.yellow)'
}

M._LEXBYLINE = true

return M
