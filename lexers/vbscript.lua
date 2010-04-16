-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- VisualBasic LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local comment = token('comment', (P("'") + 'REM ') * l.nonnewline^0)

-- strings
local string = token('string', l.delimited_range('"', nil, true, false, '\n'))

-- numbers
local number = token('number', (l.float + l.integer) * S('LlUuFf')^-2)

-- keywords
local keyword = token('keyword', word_match {
  -- control
  'If', 'Then', 'Else', 'ElseIf', 'EndIf', 'While', 'Went', 'For', 'To', 'Each',
  'In', 'Step', 'Case', 'Select', 'EndSelect', 'Return', 'Continue', 'Do',
  'Until', 'Loop', 'Next', 'With', 'Exit',
  -- operators
  'Mod', 'And', 'Not', 'Or', 'Xor', 'Is',
  -- storage types
  'Call', 'Class', 'Const', 'Dim', 'Redim', 'Function', 'Sub', 'Property',
  'End', 'Set', 'Let', 'Get', 'New', 'Randomize',
  -- storage modifiers
  'Private', 'Public', 'Default',
  -- constants
  'Empty', 'False', 'Nothing', 'Null', 'True'
})

-- types
local type = token('type', word_match {
  'Boolean', 'Byte', 'Char', 'Date', 'Decimal', 'Double', 'Long', 'Object',
  'Short', 'Single', 'String'
})

-- identifier
local identifier = token('identifier', l.word)

-- operators
local operator = token('operator', S('=><+-*^&:.,_()'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'type', type },
  { 'comment', comment },
  { 'identifier', identifier },
  { 'string', string },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
