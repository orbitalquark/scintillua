-- Copyright 2022 Mitchell. See LICENSE.
-- LPeg lexer for tool output.
-- If a warning or error is recognized, tags its filename, line, column (if available),
-- and message, and sets the line state to 1 for an error (first bit), and 2 for a warning
-- (second bit).
-- This is similar to Lexilla's errorlist lexer.

local lexer = lexer
local starts_line = lexer.starts_line
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(..., {lex_by_line = true})

local function mark_error(_, pos)
  lexer.line_state[lexer.line_from_position(pos)] = 1
  return true
end

local function mark_warning(_, pos)
  lexer.line_state[lexer.line_from_position(pos)] = 2
  return true
end

local colon = lex:tag(lexer.DEFAULT, ':' * P(' ')^-1)
local filename = lex:tag('filename', (lexer.nonnewline - ':')^1) * colon
local line = lex:tag('line', lexer.dec_num) * colon
local column = lex:tag('column', lexer.dec_num) * colon
local warning = lex:tag('message', lexer.to_eol('warning: ')) * mark_warning
local note = lex:tag('message', lexer.to_eol('note: ')) -- do not mark
local message = lex:tag('message', lexer.to_eol()) * mark_error

-- filename:line: message
-- filename:line:col: message
lex:add_rule('common', starts_line(filename) * line * column^-1 * (warning + note + message))

-- lua: filename:line: message
-- luac: filename:line: message
local lua_prefix = starts_line(lex:tag(lexer.DEFAULT, 'lua' * P('c')^-1)) * colon
lex:add_rule('lua', lua_prefix * filename * line * (warning + message))

lex:add_rule('any_line', lex:tag(lexer.DEFAULT, lexer.to_eol()))

return lex
