-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Latex LPeg lexer.
-- Modified by Brian Schott.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local line_comment = '%' * l.nonnewline^0
local block_comment = '\\begin{comment}' * (l.any - '\\end{comment}')^0 *
                      P('\\end{comment}')^-1
local comment = token(l.COMMENT, block_comment + line_comment)

-- Strings.
local math_string = '$$' * (l.any - '$$')^0 * '$$' +
                    l.delimited_range('$', '\\', true, false, '\n')
local string = token(l.STRING, math_string)

-- Commands.
local command = token(l.KEYWORD, '\\' * l.word)

-- Operators.
local operator = token(l.OPERATOR, S('$&%#{}'))

_rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'string', string },
  { 'keyword', command },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

_foldsymbols = {
  _patterns = { '\\[a-z]+', '[{}]' },
  [l.COMMENT] = { ['\\begin'] = 1, ['\\end'] = -1 },
  [l.KEYWORD] = { ['\\begin'] = 1, ['\\end'] = -1 },
  [l.OPERATOR] = { ['{'] = 1, ['}'] = -1 }
}
