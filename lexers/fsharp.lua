-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- F# LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local line_comment = P('//') * l.nonnewline^0
local block_comment = l.nested_pair('(*', '*)', true)
local comment = token(l.COMMENT, line_comment + block_comment)

-- Strings.
local sq_str = l.delimited_range("'", '\\', true, false, '\n')
local dq_str = l.delimited_range('"', '\\', true, false, '\n')
local string = token(l.STRING, sq_str + dq_str)

-- Numbers.
local number = token(l.NUMBER, (l.float + l.integer * S('uUlL')^-1))

-- Preprocessor.
local preproc_word = word_match {
  'ifndef', 'ifdef', 'if', 'else', 'endif', 'light', 'region', 'endregion'
}
local preproc = token(l.PREPROCESSOR,
                      #P('#') * l.starts_line('#' * S('\t ')^0 * preproc_word *
                      (l.nonnewline_esc^1 + l.space * l.nonnewline_esc^0)))

-- Keywords.
local keyword = token(l.KEYWORD, word_match {
  'abstract', 'and', 'as', 'assert', 'asr', 'begin', 'class', 'default',
  'delegate', 'do', 'done', 'downcast', 'downto', 'else', 'end', 'enum',
  'exception', 'false', 'finaly', 'for', 'fun', 'function', 'if', 'in',
  'iherit', 'interface', 'land', 'lazy', 'let', 'lor', 'lsl', 'lsr', 'lxor',
  'match', 'member', 'mod', 'module', 'mutable', 'namespace', 'new', 'null',
  'of', 'open', 'or', 'override', 'sig', 'static', 'struct', 'then', 'to',
  'true', 'try', 'type', 'val', 'when', 'inline', 'upcast', 'while', 'with',
  'async', 'atomic', 'break', 'checked', 'component', 'const', 'constructor',
  'continue', 'eager', 'event', 'external', 'fixed', 'functor', 'include',
  'method', 'mixin', 'process', 'property', 'protected', 'public', 'pure',
  'readonly', 'return', 'sealed', 'switch', 'virtual', 'void', 'volatile',
  'where',
  -- Booleans.
  'true', 'false'
})

-- Types.
local type = token(l.TYPE, word_match {
  'bool', 'byte', 'sbyte', 'int16', 'uint16', 'int', 'uint32', 'int64',
  'uint64', 'nativeint', 'unativeint', 'char', 'string', 'decimal', 'unit',
  'void', 'float32', 'single', 'float', 'double'
})

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

-- Operators.
local operator = token(l.OPERATOR, S('=<>+-*/^.,:;~!@#%^&|?[](){}'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'type', type },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
