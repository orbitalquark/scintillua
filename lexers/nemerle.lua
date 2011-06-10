-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Nemerle LPeg Lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token(l.WHITESPACE, l.space^1)

-- comments
local line_comment = '//' * l.nonnewline_esc^0
local block_comment = '/*' * (l.any - '*/')^0 * P('*/')^-1
local comment = token(l.COMMENT, line_comment + block_comment)

-- strings
local sq_str = P('L')^-1 * l.delimited_range("'", '\\', true, false, '\n')
local dq_str = P('L')^-1 * l.delimited_range('"', '\\', true, false, '\n')
local string = token(l.STRING, sq_str + dq_str)

-- numbers
local number = token(l.NUMBER, l.float + l.integer)

-- preprocessor
local preproc_word = word_match {
  'define', 'elif', 'else', 'endif', 'endregion', 'error', 'if', 'ifdef',
  'ifndef', 'line', 'pragma', 'region', 'undef', 'using', 'warning'
}
local preproc = token(l.PREPROCESSOR, #P('#') *
                      l.starts_line('#' * S('\t ')^0 * preproc_word))

-- keywords
local keyword = token(l.KEYWORD, word_match {
  '_', 'abstract', 'and', 'array', 'as', 'base', 'catch', 'class', 'def', 'do',
  'else', 'extends', 'extern', 'finally', 'foreach', 'for',  'fun', 'if',
  'implements', 'in', 'interface', 'internal', 'lock', 'macro', 'match',
  'module', 'mutable', 'namespace', 'new', 'out', 'override', 'params',
  'private', 'protected', 'public', 'ref', 'repeat', 'sealed', 'static',
  'struct', 'syntax', 'this', 'throw', 'try', 'type', 'typeof', 'unless',
  'until', 'using', 'variant', 'virtual', 'when', 'where', 'while',
  -- values
  'null', 'true', 'false'
})

-- types
local type = token(l.TYPE, word_match {
  'bool', 'byte', 'char', 'decimal', 'double', 'float', 'int', 'list', 'long',
  'object', 'sbyte', 'short', 'string', 'uint', 'ulong', 'ushort', 'void'
})

-- identifiers
local identifier = token(l.IDENTIFIER, l.word)

-- operators
local operator = token(l.OPERATOR, S('+-/*%<>!=^&|?~:;.()[]{}'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'type', type },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'preproc', preproc },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

_foldsymbols = {
  _patterns = { '%l+', '[{}]', '/%*', '%*/' },
  comment = { ['/*'] = 1, ['*/'] = -1 },
  preprocessor = {
    region = 1, endregion = -1,
    ['if'] = 1, ifdef = 1, ifndef = 1, endif = -1
  },
  operator = { ['{'] = 1, ['}'] = -1 }
}
