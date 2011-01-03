-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Lisp LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token(l.WHITESPACE, l.space^1)

-- comments
local line_comment = ';' * l.nonnewline^0
local block_comment = '#| ' * (l.any - ' |#')^0 * ' |#'
local comment = token(l.COMMENT, line_comment + block_comment)

local word = l.alpha * (l.alnum + '_' + '-')^0

-- strings
local literal = "'" * word
local dq_str = l.delimited_range('"', '\\', true)
local string = token(l.STRING, literal + dq_str)

-- numbers
local number = token(l.NUMBER, P('-')^-1 * l.digit^1 * (S('./') * l.digit^1)^-1)

-- keywords
local keyword = token(l.KEYWORD, word_match({
  'defclass', 'defconstant', 'defgeneric', 'define-compiler-macro',
  'define-condition', 'define-method-combination', 'define-modify-macro',
  'define-setf-expander', 'define-symbol-macro', 'defmacro', 'defmethod',
  'defpackage', 'defparameter', 'defsetf', 'defstruct', 'deftype', 'defun',
  'defvar',
  'abort', 'assert', 'block', 'break', 'case', 'catch', 'ccase', 'cerror',
  'cond', 'ctypecase', 'declaim', 'declare', 'do', 'do*', 'do-all-symbols',
  'do-external-symbols', 'do-symbols', 'dolist', 'dotimes', 'ecase', 'error',
  'etypecase', 'eval-when', 'flet', 'handler-bind', 'handler-case', 'if',
  'ignore-errors', 'in-package', 'labels', 'lambda', 'let', 'let*', 'locally',
  'loop', 'macrolet', 'multiple-value-bind', 'proclaim', 'prog', 'prog*',
  'prog1', 'prog2', 'progn', 'progv', 'provide', 'require', 'restart-bind',
  'restart-case', 'restart-name', 'return', 'return-from', 'signal',
  'symbol-macrolet', 'tagbody', 'the', 'throw', 'typecase', 'unless',
  'unwind-protect', 'when', 'with-accessors', 'with-compilation-unit',
  'with-condition-restarts', 'with-hash-table-iterator',
  'with-input-from-string', 'with-open-file', 'with-open-stream',
  'with-output-to-string', 'with-package-iterator', 'with-simple-restart',
  'with-slots', 'with-standard-io-syntax',
  't', 'nil'
}, '-'))

-- identifiers
local identifier = token(l.IDENTIFIER, word)

-- operators
local operator = token(l.OPERATOR, S('<>=*/+-`@%()'))

-- entity
local entity = token('entity', '&' * word)

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'operator', operator },
  { 'entity', entity },
  { 'any_char', l.any_char },
}

_tokenstyles = {
  { 'entity', l.style_variable },
}
