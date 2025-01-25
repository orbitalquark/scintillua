-- Copyright 2025 Chris Clark and Mitchell. See LICENSE.
-- todo.txt https://github.com/too-much-todotxt/spec LPeg lexer.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

local not_whitespace = lexer.any - lexer.space - P(':')
local not_whitespace_word = not_whitespace^1


-- Done/Complete items, map to comment style
lex:add_rule('done', lex:tag(lexer.COMMENT, lexer.starts_line(lexer.to_eol('x '))))

-- Priority
--lex:add_rule('priority', lex:tag(lexer.LIST .. '.priority', lexer.starts_line(P('(') * lexer.upper * P(') '))))
--lex:add_rule('priority', lex:tag(lexer.LIST, lexer.starts_line(P('(') * lexer.upper * P(') '))))


-- priority A-Z can have different styles. Below sets A-F as different and then G-Z all the same - similar approach as Markor Android app https://github.com/gsantner/markor/blob/master/app/src/main/java/net/gsantner/markor/format/todotxt/TodoTxtBasicSyntaxHighlighter.java#L13
-- in theme properties:
--      scintillua.styles.list.priority
--      scintillua.styles.list.priority.a
--      scintillua.styles.list.priority.b
--      scintillua.styles.list.priority....
-- Example
--      scintillua.styles.list.priority=fore:$(scintillua.colors.grey),bold
--      scintillua.styles.list.priority.a=fore:$(scintillua.colors.red),bold
--      scintillua.styles.list.priority.b=fore:$(scintillua.colors.orange),bold
--      scintillua.styles.list.priority.c=fore:$(scintillua.colors.green),bold
--      scintillua.styles.list.priority.d=fore:$(scintillua.colors.blue),bold
--      scintillua.styles.list.priority.e=fore:$(scintillua.colors.purple),bold
--      scintillua.styles.list.priority.f=fore:$(scintillua.colors.dark_grey),bold
local priority = P(false)
for letter in string.gmatch('abcdefghijklmnopqrstuvwxyz', '.') do
  local tag = lex:tag(lexer.LIST .. '.priority.' .. letter, lexer.starts_line('(' .. letter:upper() .. ') '))
  priority = priority + tag
end
lex:add_rule('priority', priority)


-- key:value
-- https://github.com/too-much-todotxt/spec/issues/23
-- simple same style for key, colon, and value - useful for URLs which look like key/value pairs
--lex:add_rule('key_value', lex:tag(lexer.NUMBER, not_whitespace_word*P(':')*not_whitespace_word))
-- lexer.word too restrictive according to todo.txt spec
-- below works for alpha words but fails to match; due:2025-01-31 hide:1 rec:1b rec2:+2w p:2
--lex:add_rule('key_value', lex:tag(lexer.NUMBER, lexer.word*P(':')*lexer.word))

-- Different style for key and value so they are clearly marked
local key = lex:tag(lexer.KEYWORD, not_whitespace_word)
local colon = lex:tag(lexer.OPERATOR, P(':'))
local value = lex:tag(lexer.CONSTANT, not_whitespace_word)
lex:add_rule('key_value', key * colon * value)


-- date - any context, for now treat due and complete (or anywhere in string) the same
lex:add_rule('date', lex:tag(lexer.NUMBER, lexer.digit^4*P('-') * lexer.digit^2 * P('-') * lexer.digit^2 * #lexer.space))


-- Project and Context last, as same characters can show up in key:value

-- Project +
lex:add_rule('project', lex:tag(lexer.REFERENCE, lexer.range('+', lexer.space, true)))  -- REFERENCE and lexer.LINK seem the same
-- Context @
lex:add_rule('context', lex:tag(lexer.ITALIC, lexer.range('@', lexer.space, true)))


lex:add_rule('todo_txt', lex:tag(lexer.STRING, lexer.any))

-- style notes
-- OPERATOR? - sort of bold
-- lexer.KEYWORD - different color
-- Consider using:
-- lexer.LABEL
-- lexer.TYPE

return lex
