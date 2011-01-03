-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Eiffel LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token(l.WHITESPACE, l.space^1)

-- comments
local comment = token(l.COMMENT, '--' * l.nonnewline^0)

-- strings
local sq_str = l.delimited_range("'", '\\', true, false, '\n')
local dq_str = l.delimited_range('"', '\\', true, false, '\n')
local string = token(l.STRING, sq_str + dq_str)

-- numbers
local number = token(l.NUMBER, l.float + l.integer)

-- keywords
local keyword = token(l.KEYWORD, word_match {
  'alias', 'all', 'and', 'as', 'check', 'class', 'creation', 'debug',
  'deferred', 'do', 'else', 'elseif', 'end', 'ensure', 'expanded', 'export',
  'external', 'feature', 'from', 'frozen', 'if', 'implies', 'indexing', 'infix',
  'inherit', 'inspect', 'invariant', 'is', 'like', 'local', 'loop', 'not',
  'obsolete', 'old', 'once', 'or', 'prefix', 'redefine', 'rename', 'require',
  'rescue', 'retry', 'select', 'separate', 'then', 'undefine', 'until',
  'variant', 'when', 'xor',
  'current', 'false', 'precursor', 'result', 'strip', 'true', 'unique', 'void'
})

-- types
local type = token(l.TYPE, word_match {
  'character', 'string', 'bit', 'boolean', 'integer', 'real', 'none', 'any'
})

-- identifiers
local identifier = token(l.IDENTIFIER, l.word)

-- operators
local operator = token(l.OPERATOR, S('=!<>+-/*%&|^~.,:;?()[]{}'))

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
