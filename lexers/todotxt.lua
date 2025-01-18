-- Copyright 2025 Chris Clark
-- todo.txt https://github.com/too-much-todotxt/spec LPeg lexer.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new('todotxt')

local not_whitespace = lexer.any - lexer.space - P(':')
local not_whitespace_word = not_whitespace * not_whitespace^0


-- Done/Complete items, map to comment style
lex:add_rule('done', lex:tag(lexer.COMMENT, lexer.starts_line(lexer.to_eol('x '))))

-- Priority, treat A, B, C as unique, D+ same style
lex:add_rule('priority_A', lex:tag(lexer.ERROR, lexer.starts_line('(A) ')))
lex:add_rule('priority_B', lex:tag(lexer.PREPROCESSOR, lexer.starts_line('(B) ')))
lex:add_rule('priority_C', lex:tag(lexer.NUMBER, lexer.starts_line('(C) ')))
lex:add_rule('priority', lex:tag(lexer.BOLD, lexer.starts_line(P('(') * lexer.upper * P(') '))))

-- Idea, lump some priority styles together
--lex:add_rule('priority', lex:tag(lexer.NUMBER, lexer.starts_line('(A) ') + lexer.starts_line('(B) ') + lexer.starts_line('(C) ') ))


-- key:value
-- https://github.com/too-much-todotxt/spec/issues/23
-- TODO different style for key and value so they are clearly marked?
lex:add_rule('key_value', lex:tag(lexer.NUMBER, not_whitespace_word*P(':')*not_whitespace_word))
-- lexer.word too restrictive according to todo.txt spec
-- below works for alpha words but fails to match; due:2025-01-31 hide:1 rec:1b rec2:+2w p:2
--lex:add_rule('key_value', lex:tag(lexer.NUMBER, lexer.word*P(':')*lexer.word))


-- date - any context, for now treat due and complete (or anywhere in string) the same
lex:add_rule('date', lex:tag(lexer.KEYWORD, lexer.digit^4*P('-') * lexer.digit^2 * P('-') * lexer.digit^2 * #lexer.space))


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
