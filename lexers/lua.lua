-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Lua LPeg lexer

-- Original written by Peter Odding, 2007/04/04

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', S('\r\n\f\t ')^1)

local longstring = #('[[' + ('[' * P('=')^0 * '['))
local longstring = longstring * P(function(input, index)
  local level = input:match('^%[(=*)%[', index)
  if level then
    local _, stop = input:find(']'..level..']', index, true)
    return stop and stop + 1 or #input + 1
  end
end)

-- comments
local line_comment = '--' * nonnewline^0
local block_comment = '--' * longstring
local comment = token('comment', block_comment + line_comment)

-- strings
local sq_str = delimited_range("'", '\\', true)
local dq_str = delimited_range('"', '\\', true)
local string = token('string', sq_str + dq_str + longstring)

-- numbers
local lua_integer = P('-')^-1 * (hex_num + dec_num)
local number = token('number', float + lua_integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for',
  'function', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
  'return', 'then', 'true', 'until', 'while'
}))

-- functions
local func = token('function', word_match(word_list{
  'assert', 'collectgarbage', 'dofile', 'error', 'getfenv', 'getmetatable',
  'gcinfo', 'ipairs', 'loadfile', 'loadlib', 'loadstring', 'next', 'pairs',
  'pcall', 'print', 'rawequal', 'rawget', 'rawset', 'require', 'setfenv',
  'setmetatable', 'tonumber', 'tostring', 'type', 'unpack', 'xpcall'
}))

-- constants
local constant = token('constant', word_match(word_list{
  '_G', '_VERSION', 'LUA_PATH', '_LOADED', '_REQUIREDNAME', '_ALERT',
  '_ERRORMESSAGE', '_PROMPT'
}))

-- identifiers
local word = (R('AZ', 'az', '\127\255') + '_') * (alnum + '_')^0
local identifier = token('identifier', word)

-- operators
local operator = token('operator', '~=' + S('+-*/%^#=<>;:,.{}[]()'))

function LoadTokens()
  local lua = lua
  add_token(lua, 'whitespace', ws)
  add_token(lua, 'keyword', keyword)
  add_token(lua, 'function', func)
  add_token(lua, 'constant', constant)
  add_token(lua, 'identifier', identifier)
  add_token(lua, 'string', string)
  add_token(lua, 'comment', comment)
  add_token(lua, 'number', number)
  add_token(lua, 'operator', operator)
  add_token(lua, 'any_char', any_char)
end
