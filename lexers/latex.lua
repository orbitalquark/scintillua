-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Latex LPeg lexer.
-- Modified by Brian Schott.
-- Modified by Robert Gieseke.

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
local comment = token(l.COMMENT, line_comment + block_comment)

-- Sections.
local section = token('section', '\\' * word_match {
  'part', 'chapter', 'section', 'subsection', 'subsubsection', 'paragraph',
  'subparagraph'
} * P('*')^-1)

-- Math environments.
local math_word = word_match {
  'align', 'displaymath', 'eqnarray', 'equation', 'gather', 'math', 'multline'
}
local math_begin_end = (P('begin') + P('end')) *
                       '{' * math_word * P('*')^-1 * '}'
local math = token('math', '$' + '\\' * (S('[]()') + math_begin_end))

-- LaTeX environments.
local environment = token('environment', '\\' * (P('begin') + P('end')) *
                                         '{' * l.word * P('*')^-1 * '}')

-- Commands.
local command = token(l.KEYWORD, '\\' * (l.alpha^1 + S('#$&~_^%{}')))

-- Operators.
local operator = token(l.OPERATOR, S('&#{}[]'))

_rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'math', math },
  { 'environment', environment },
  { 'section', section },
  { 'keyword', command },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

_tokenstyles = {
  { 'environment', l.style_tag },
  { 'math', l.style_function },
  { 'section', l.style_class },
}

_foldsymbols = {
  _patterns = { '\\[a-z]+', '[{}]', '%%' },
  [l.COMMENT] = {
    ['\\begin'] = 1, ['\\end'] = -1, ['%'] = l.fold_line_comments('%')
  },
  ['environment'] = { ['\\begin'] = 1, ['\\end'] = -1 },
  [l.OPERATOR] = { ['{'] = 1, ['}'] = -1 }
}
