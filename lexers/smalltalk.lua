-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Smalltalk LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', delimited_range('"', nil, true))

-- strings
local sq_str = delimited_range("'", '\\', true)
local literal = '$' * word
local string = token('string', sq_str + literal)

-- numbers
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'true', 'false', 'nil', 'self', 'super', 'isNil', 'not', 'Smalltalk',
  'Transcript'
}))

-- types
local type = token('type', word_match(word_list{
  'Date', 'Time', 'Boolean', 'True', 'False', 'Character', 'String', 'Array',
  'Symbol', 'Integer', 'Object'
}))

-- identifiers
local identifier = token('identifier', word)

-- labels
local label = token('label', '#' * word)

-- operators
local operator = token('operator', S(':=_<>+-/*!()[]'))

function LoadTokens()
  local smalltalk = smalltalk
  add_token(smalltalk, 'whitespace', ws)
  add_token(smalltalk, 'keyword', keyword)
  add_token(smalltalk, 'type', type)
  add_token(smalltalk, 'identifier', identifier)
  add_token(smalltalk, 'string', string)
  add_token(smalltalk, 'comment', comment)
  add_token(smalltalk, 'number', number)
  add_token(smalltalk, 'label', label)
  add_token(smalltalk, 'operator', operator)
  add_token(smalltalk, 'any_char', any_char)
end

function LoadStyle()
  add_style('label', style_variable)
end
