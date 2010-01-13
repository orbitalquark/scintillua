-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Lisp LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = ';' * nonnewline^0
local block_comment = '#| ' * (any - ' |#')^0 * ' |#'
local comment = token('comment', line_comment + block_comment)

-- strings
local literal = "'" * word
local dq_str = delimited_range('"', '\\', true)
local string = token('string', literal + dq_str)

-- numbers
local number = token('number', P('-')^-1 * digit^1 * (S('./') * digit^1)^-1)

-- keywords
local keyword = token('keyword', word_match(word_list{
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
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('<>=*/+-`@%()'))

-- entity
local entity = token('entity', '&' * word)

function LoadTokens()
  local lisp = lisp
  add_token(lisp, 'whitespace', ws)
  add_token(lisp, 'comment', comment)
  add_token(lisp, 'string', string)
  add_token(lisp, 'number', number)
  add_token(lisp, 'keyword', keyword)
  add_token(lisp, 'identifier', identifier)
  add_token(lisp, 'operator', operator)
  add_token(lisp, 'entity', entity)
  add_token(lisp, 'any_char', any_char)
end

function LoadStyles()
  add_style('entity', style_variable)
end
