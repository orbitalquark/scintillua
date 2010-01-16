-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Groovy LPeg Lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = '//' * nonnewline_esc^0
local block_comment = '/*' * (any - '*/')^0 * P('*/')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local sq_str = delimited_range("'", '\\', true)
local dq_str = delimited_range('"', '\\', true)
local heredoc = '<<<' * P(function(input, index)
  local _, e, delimiter = input:find('([%a_][%w_]*)[\n\r\f]+', index)
  if delimiter then
    local _, e = input:find('[\n\r\f]+'..delimiter, e)
    return e and e + 1
  end
end)
local string = token('string', sq_str + dq_str + heredoc)

-- numbers
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'abstract', 'break', 'case', 'catch', 'continue', 'default', 'do', 'else',
  'extends', 'final', 'finally', 'for', 'if', 'implements', 'instanceof',
  'native', 'new', 'private', 'protected', 'public', 'return', 'static',
  'switch', 'synchronized', 'throw', 'throws', 'transient', 'try', 'volatile',
  'while', 'strictfp', 'package', 'import', 'as', 'assert', 'def', 'mixin',
  'property', 'test', 'using', 'in',
  'false', 'null', 'super', 'this', 'true', 'it'
}))

-- functions
local func = token('function', word_match(word_list{
  'abs', 'any', 'append', 'asList', 'asWritable', 'call', 'collect',
  'compareTo', 'count', 'div', 'dump', 'each', 'eachByte', 'eachFile',
  'eachLine', 'every', 'find', 'findAll', 'flatten', 'getAt', 'getErr', 'getIn',
  'getOut', 'getText', 'grep', 'immutable', 'inject', 'inspect', 'intersect',
  'invokeMethods', 'isCase', 'join', 'leftShift', 'minus', 'multiply',
  'newInputStream', 'newOutputStream', 'newPrintWriter', 'newReader',
  'newWriter', 'next', 'plus', 'pop', 'power', 'previous', 'print', 'println',
  'push', 'putAt', 'read', 'readBytes', 'readLines', 'reverse', 'reverseEach',
  'round', 'size', 'sort', 'splitEachLine', 'step', 'subMap', 'times',
  'toInteger', 'toList', 'tokenize', 'upto', 'waitForOrKill', 'withPrintWriter',
  'withReader', 'withStream', 'withWriter', 'withWriterAppend', 'write',
  'writeLine'
}))

-- types
local type = token('type', word_match(word_list{
  'boolean', 'byte', 'char', 'class', 'double', 'float', 'int', 'interface',
  'long', 'short', 'void'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('=~|!<>+-/*?&.,:;()[]{}'))

function LoadTokens()
  local groovy = groovy
  add_token(groovy, 'whitespace', ws)
  add_token(groovy, 'keyword', keyword)
  add_token(groovy, 'function', func)
  add_token(groovy, 'type', type)
  add_token(groovy, 'identifier', identifier)
  add_token(groovy, 'string', string)
  add_token(groovy, 'comment', comment)
  add_token(groovy, 'number', number)
  add_token(groovy, 'operator', operator)
  add_token(groovy, 'any_char', any_char)
end
