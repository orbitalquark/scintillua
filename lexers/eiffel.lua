-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Eiffel LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', '--' * nonnewline^0)

-- strings
local sq_str = delimited_range("'", '\\', true, false, '\n')
local dq_str = delimited_range('"', '\\', true, false, '\n')
local string = token('string', sq_str + dq_str)

-- numbers
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'alias', 'all', 'and', 'as', 'check', 'class', 'creation', 'debug',
  'deferred', 'do', 'else', 'elseif', 'end', 'ensure', 'expanded', 'export',
  'external', 'feature', 'from', 'frozen', 'if', 'implies', 'indexing', 'infix',
  'inherit', 'inspect', 'invariant', 'is', 'like', 'local', 'loop', 'not',
  'obsolete', 'old', 'once', 'or', 'prefix', 'redefine', 'rename', 'require',
  'rescue', 'retry', 'select', 'separate', 'then', 'undefine', 'until',
  'variant', 'when', 'xor',
  'current', 'false', 'precursor', 'result', 'strip', 'true', 'unique', 'void'
}))

-- types
local type = token('type', word_match(word_list{
  'character', 'string', 'bit', 'boolean', 'integer', 'real', 'none', 'any'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('=!<>+-/*%&|^~.,:;?()[]{}'))

function LoadTokens()
  local eiffel = eiffel
  add_token(eiffel, 'whitespace', ws)
  add_token(eiffel, 'keyword', keyword)
  add_token(eiffel, 'type', type)
  add_token(eiffel, 'identifier', identifier)
  add_token(eiffel, 'string', string)
  add_token(eiffel, 'comment', comment)
  add_token(eiffel, 'number', number)
  add_token(eiffel, 'operator', operator)
  add_token(eiffel, 'any_char', any_char)
end
