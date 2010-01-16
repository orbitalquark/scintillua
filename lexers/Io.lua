-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Io LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = (P('#') + '//') * nonnewline^0
local block_comment = '/*' * (any - '*/')^0 * P('*/')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local sq_str = delimited_range("'", '\\', true)
local dq_str = delimited_range('"', '\\', true)
local tq_str = '"""' * (any - '"""')^0 * P('"""')^-1
local string = token('string', sq_str + dq_str + tq_str)

-- numbers
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'block', 'method', 'while', 'foreach', 'if', 'else', 'do', 'super', 'self',
  'clone', 'proto', 'setSlot', 'hasSlot', 'type', 'write', 'print', 'forward'
}))

-- types
local type = token('type', word_match(word_list{
  'Block', 'Buffer', 'CFunction', 'Date', 'Duration', 'File', 'Future', 'List',
  'LinkedList', 'Map', 'Nop', 'Message', 'Nil', 'Number', 'Object', 'String',
  'WeakLink'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('`~@$%^&*-+/=\\<>?.,:;()[]{}'))

function LoadTokens()
  local io = Io
  add_token(io, 'whitespace', ws)
  add_token(io, 'keyword', keyword)
  add_token(io, 'type', type)
  add_token(io, 'identifier', identifier)
  add_token(io, 'string', string)
  add_token(io, 'comment', comment)
  add_token(io, 'number', number)
  add_token(io, 'operator', operator)
  add_token(io, 'any_char', any_char)
end
