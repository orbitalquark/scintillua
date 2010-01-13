-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Actionscript LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = '//' * nonnewline^0
local block_comment = '/*' * (any - '*/')^0 * '*/'
local comment = token('comment', line_comment + block_comment)

-- strings
local sq_str = delimited_range("'", '\\', true, false, '\n')
local dq_str = delimited_range('"', '\\', true, false, '\n')
local ml_str = '<![CDATA[' * (any - ']]>')^0 * ']]>'
local string = token('string', sq_str + dq_str + ml_str)

-- numbers
local number = token('number', (float + integer) * S('LlUuFf')^-2)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'break', 'continue', 'delete', 'do', 'else', 'for', 'function', 'if', 'in',
  'new', 'on', 'return', 'this', 'typeof', 'var', 'void', 'while', 'with',
  'NaN', 'Infinity', 'false', 'null', 'true', 'undefined',
  -- reserved for future use
  'abstract', 'case', 'catch', 'class', 'const', 'debugger', 'default',
  'export', 'extends', 'final', 'finally', 'goto', 'implements', 'import',
  'instanceof', 'interface', 'native', 'package', 'private', 'Void',
  'protected', 'public', 'dynamic', 'static', 'super', 'switch', 'synchonized',
  'throw', 'throws', 'transient', 'try', 'volatile'
}))

-- types
local type = token('type', word_match(word_list{
  'Array', 'Boolean', 'Color', 'Date', 'Function', 'Key', 'MovieClip', 'Math',
  'Mouse', 'Number', 'Object', 'Selection', 'Sound', 'String', 'XML', 'XMLNode',
  'XMLSocket',
  -- reserved for future use
  'boolean', 'byte', 'char', 'double', 'enum', 'float', 'int', 'long', 'short'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('=!<>+-/*%&|^~.,;?()[]{}'))

function LoadTokens()
  local as = actionscript
  add_token(as, 'whitespace', ws)
  add_token(as, 'comment', comment)
  add_token(as, 'string', string)
  add_token(as, 'number', number)
  add_token(as, 'keyword', keyword)
  add_token(as, 'type', type)
  add_token(as, 'identifier', identifier)
  add_token(as, 'operator', operator)
  add_token(as, 'any_char', any_char)
end
