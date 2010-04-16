-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Applescript LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local line_comment = '--' * l.nonnewline^0
local block_comment = '(*' * (l.any - '*)')^0 * P('*)')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local sq_str = l.delimited_range("'", '\\', true, false, '\n')
local dq_str = l.delimited_range('"', '\\', true, false, '\n')
local string = token('string', sq_str + dq_str)

-- numbers
local number = token('number', l.float + l.integer)

-- keywords
local keyword = token('keyword', word_match({
  'script', 'property', 'prop', 'end', 'copy', 'to', 'set', 'global', 'local',
  'on', 'to', 'of', 'in', 'given', 'with', 'without', 'return', 'continue',
  'tell', 'if', 'then', 'else', 'repeat', 'times', 'while', 'until', 'from',
  'exit', 'try', 'error', 'considering', 'ignoring', 'timeout', 'transaction',
  'my', 'get', 'put', 'into', 'is',
  -- references
  'each', 'some', 'every', 'whose', 'where', 'id', 'index', 'first', 'second',
  'third', 'fourth', 'fifth', 'sixth', 'seventh', 'eighth', 'ninth', 'tenth',
  'last', 'front', 'back', 'st', 'nd', 'rd', 'th', 'middle', 'named', 'through',
  'thru', 'before', 'after', 'beginning', 'the',
  -- commands
  'close', 'copy', 'count', 'delete', 'duplicate', 'exists', 'launch', 'make',
  'move', 'open', 'print', 'quit', 'reopen', 'run', 'save', 'saving',
  -- operators
  'div', 'mod', 'and', 'not', 'or', 'as', 'contains', 'equal', 'equals',
  'isn\'t',
}, "'", true))

-- constants
local constant = token('constant', word_match({
  'case', 'diacriticals', 'expansion', 'hyphens', 'punctuation',
  -- predefined variables
  'it', 'me', 'version', 'pi', 'result', 'space', 'tab', 'anything',
  -- text styles
  'bold', 'condensed', 'expanded', 'hidden', 'italic', 'outline', 'plain',
  'shadow', 'strikethrough', 'subscript', 'superscript', 'underline',
  -- save options
  'ask', 'no', 'yes',
  -- booleans
  'false', 'true',
  -- date and time
  'weekday', 'monday', 'mon', 'tuesday', 'tue', 'wednesday', 'wed', 'thursday',
  'thu', 'friday', 'fri', 'saturday', 'sat', 'sunday', 'sun', 'month',
  'january', 'jan', 'february', 'feb', 'march', 'mar', 'april', 'apr', 'may',
  'june', 'jun', 'july', 'jul', 'august', 'aug', 'september', 'sep', 'october',
  'oct', 'november', 'nov', 'december', 'dec', 'minutes', 'hours', 'days',
  'weeks'
}, nil, true))

-- identifiers
local identifier = token('identifier', (l.alpha + '_') * l.alnum^0)

-- operators
local operator = token('operator', S('+-^*/&<>=:,(){}'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'constant', constant },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
