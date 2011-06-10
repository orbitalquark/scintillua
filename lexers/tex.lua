-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- April 2010 Robert Gieseke, combined LaTeX and ConTeXt lexing
-- TeX LPeg lexer

-- TODO: Embed LuaTeX
--   ConTeXt: \directlua{...}
--     or \startlua ... \stoplua
--   LaTeX: see pdf 'LuaTEXtra references'

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token(l.WHITESPACE, l.space^1)

-- comments
local line_comment = '%' * l.nonnewline^0
local block_comment = '\\begin{comment}' * (l.any - '\\end{comment}')^0 *
                      '\\end{comment}'
local comment = token(l.COMMENT, line_comment + block_comment)

-- environment
-- LaTeX environments
local env_latex = '\\' * (P('begin') + 'end') * '{' *  word_match({
  'abstract', 'array', 'center', 'description', 'displaymath', 'document',
  'enumerate', 'eqnarray', 'equation', 'figure', 'flushleft', 'flushright',
  'itemize', 'list', 'math', 'minipage', 'picture', 'quotation', 'quote',
  'tabbing', 'table', 'tabular', 'thebibliography', 'theorem', 'titlepage',
  'trivlist', 'verbatim', 'verse'
}) * '}'
local env_latex_math = '\\' * S('[]()') + '$' -- covers '$$' as well
-- ConTeXt environments
local env_context = '\\' * (P('start') * l.word + 'stop' * l.word)
local environment = token('environment', env_latex + env_latex_math +
                          env_context)

-- commands
local escapes = S('$%_{}&#')
local command = token(l.KEYWORD, '\\' * (l.alpha^1 + escapes))

-- operators
local operator = token(l.OPERATOR, S('$&%#{}[]'))

_rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'environment', environment },
  { 'keyword', command },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

_tokenstyles = {
  { 'environment', l.style_tag },
}

_foldsymbols = {
  _patterns = { '\\[a-z]+', '[{}]' },
  comment = { ['\\begin'] = 1, ['\\end'] = -1 },
  keyword = { ['\\begin'] = 1, ['\\end'] = -1 },
  operator = { ['{'] = 1, ['}'] = -1 }
}
