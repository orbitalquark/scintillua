-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Groovy LPeg Lexer

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
local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local triple_sq_str = "'''" * (l.any - "'''")^0 * P("'''")^-1
local triple_dq_str = '"""' * (l.any - '"""')^0 * P('"""')^-1
local regex_str = l.delimited_range('/', '\\', nil, nil, '\n')
local string = token(l.STRING, triple_sq_str + triple_dq_str + sq_str + dq_str +
                     regex_str)

-- numbers
local number = token(l.NUMBER, l.float + l.integer)

-- keywords
local keyword = token(l.KEYWORD, word_match {
  'abstract', 'break', 'case', 'catch', 'continue', 'default', 'do', 'else',
  'extends', 'final', 'finally', 'for', 'if', 'implements', 'instanceof',
  'native', 'new', 'private', 'protected', 'public', 'return', 'static',
  'switch', 'synchronized', 'throw', 'throws', 'transient', 'try', 'volatile',
  'while', 'strictfp', 'package', 'import', 'as', 'assert', 'def', 'mixin',
  'property', 'test', 'using', 'in',
  'false', 'null', 'super', 'this', 'true', 'it'
})

-- functions
local func = token(l.FUNCTION, word_match {
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
})

-- types
local type = token(l.TYPE, word_match {
  'boolean', 'byte', 'char', 'class', 'double', 'float', 'int', 'interface',
  'long', 'short', 'void'
})

-- identifiers
local identifier = token(l.IDENTIFIER, l.word)

-- operators
local operator = token(l.OPERATOR, S('=~|!<>+-/*?&.,:;()[]{}'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'function', func },
  { 'type', type },
  { 'identifier', identifier },
  { 'comment', comment },
  { 'string', string },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

_foldsymbols = {
  _patterns = { '[{}]', '/%*', '%*/' },
  operator = { ['{'] = 1, ['}'] = -1 },
  comment = { ['/*'] = 1, ['*/'] = -1 }
}
