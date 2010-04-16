-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Io LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local line_comment = (P('#') + '//') * l.nonnewline^0
local block_comment = '/*' * (l.any - '*/')^0 * P('*/')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local tq_str = '"""' * (l.any - '"""')^0 * P('"""')^-1
local string = token('string', sq_str + dq_str + tq_str)

-- numbers
local number = token('number', l.float + l.integer)

-- keywords
local keyword = token('keyword', word_match {
  'block', 'method', 'while', 'foreach', 'if', 'else', 'do', 'super', 'self',
  'clone', 'proto', 'setSlot', 'hasSlot', 'type', 'write', 'print', 'forward'
})

-- types
local type = token('type', word_match {
  'Block', 'Buffer', 'CFunction', 'Date', 'Duration', 'File', 'Future', 'List',
  'LinkedList', 'Map', 'Nop', 'Message', 'Nil', 'Number', 'Object', 'String',
  'WeakLink'
})

-- identifiers
local identifier = token('identifier', l.word)

-- operators
local operator = token('operator', S('`~@$%^&*-+/=\\<>?.,:;()[]{}'))

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
