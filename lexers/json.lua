--------------------------------------------------------------------------------
-- The MIT License
--
-- Copyright (c) 2009 Brian "Sir Alaran" Schott
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--------------------------------------------------------------------------------

-- Based off of lexer code by Mitchell

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token(l.WHITESPACE, l.space^1)

local lit_newline = P('\r')^-1 * P('\n')

-- comments
local block_comment = '/*' * (l.any - '*/')^0 * P('*/')^-1
local comment = token(l.COMMENT, block_comment)

-- strings
local sq_str = P('u')^-1 * l.delimited_range("'", '\\', true, false, '\n')
local dq_str = P('U')^-1 * l.delimited_range('"', '\\', true, false, '\n')
local string = token(l.STRING, sq_str + dq_str)

-- numbers
local dec = l.digit^1 * S('Ll')^-1
local integer = S('+-')^-1 * dec
local number = token(l.NUMBER, l.float + integer)

-- keywords
local keyword = token(l.KEYWORD, word_match { "true", "false", "null" })

-- operators
local operator = token(l.OPERATOR, S('[]{}:,'))

_rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'string', string },
  { 'number', number },
  { 'keyword', keyword },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

_foldsymbols = {
  _patterns = { '[%[%]{}]', '/%*', '%*/' },
  comment = { ['/*'] = 1, ['*/'] = -1 },
  operator = { ['['] = 1, [']'] = -1, ['{'] = 1, ['}'] = -1 }
}
