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

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

local lit_newline = P('\r')^-1 * P('\n')

-- comments
local block_comment = '/*' * (any - '*/')^0 * P('*/')^-1
local comment = token('comment', block_comment)

-- strings
local sq_str = P('u')^-1 * delimited_range("'", '\\', true, false, '\n')
local dq_str = P('U')^-1 * delimited_range('"', '\\', true, false, '\n')
local string = token('string', sq_str + dq_str)

-- numbers
local dec = digit^1 * S('Ll')^-1
local integer = S('+-')^-1 * (dec)
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{"true", "false", "null"}))

-- operators
local operator = token('operator', S('[]{}:,'))

function LoadTokens()
  local json = json
  add_token(json, 'whitespace', ws)
  add_token(json, 'comment', comment)
  add_token(json, 'string', string)
  add_token(json, 'number', number)
  add_token(json, 'keyword', keyword)
  add_token(json, 'operator', operator)
  add_token(json, 'any_char', any_char)
end
