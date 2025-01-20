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

local priority_a = lex:tag(lexer.LIST .. '.priority.a', lexer.starts_line('(A) '))
local priority_b = lex:tag(lexer.LIST .. '.priority.b', lexer.starts_line('(B) '))
local priority_c = lex:tag(lexer.LIST .. '.priority.c', lexer.starts_line('(C) '))
local priority_d = lex:tag(lexer.LIST .. '.priority.d', lexer.starts_line('(D) '))
local priority_e = lex:tag(lexer.LIST .. '.priority.e', lexer.starts_line('(E) '))
local priority_f = lex:tag(lexer.LIST .. '.priority.f', lexer.starts_line('(F) '))
-- See priority_g_z
--local priority_g = lex:tag(lexer.LIST .. '.priority.g', lexer.starts_line('(G) '))
--local priority_h = lex:tag(lexer.LIST .. '.priority.h', lexer.starts_line('(H) '))
--local priority_i = lex:tag(lexer.LIST .. '.priority.i', lexer.starts_line('(I) '))
--local priority_j = lex:tag(lexer.LIST .. '.priority.j', lexer.starts_line('(J) '))
--local priority_k = lex:tag(lexer.LIST .. '.priority.k', lexer.starts_line('(K) '))
--local priority_l = lex:tag(lexer.LIST .. '.priority.l', lexer.starts_line('(L) '))
--local priority_m = lex:tag(lexer.LIST .. '.priority.m', lexer.starts_line('(M) '))
--local priority_n = lex:tag(lexer.LIST .. '.priority.n', lexer.starts_line('(N) '))
--local priority_o = lex:tag(lexer.LIST .. '.priority.o', lexer.starts_line('(O) '))
--local priority_p = lex:tag(lexer.LIST .. '.priority.p', lexer.starts_line('(P) '))
--local priority_q = lex:tag(lexer.LIST .. '.priority.q', lexer.starts_line('(Q) '))
--local priority_r = lex:tag(lexer.LIST .. '.priority.r', lexer.starts_line('(R) '))
--local priority_s = lex:tag(lexer.LIST .. '.priority.s', lexer.starts_line('(S) '))
--local priority_t = lex:tag(lexer.LIST .. '.priority.t', lexer.starts_line('(T) '))
--local priority_u = lex:tag(lexer.LIST .. '.priority.u', lexer.starts_line('(U) '))
--local priority_v = lex:tag(lexer.LIST .. '.priority.v', lexer.starts_line('(V) '))
--local priority_w = lex:tag(lexer.LIST .. '.priority.w', lexer.starts_line('(W) '))
--local priority_x = lex:tag(lexer.LIST .. '.priority.x', lexer.starts_line('(X) '))
--local priority_y = lex:tag(lexer.LIST .. '.priority.y', lexer.starts_line('(Y) '))
--local priority_z = lex:tag(lexer.LIST .. '.priority.z', lexer.starts_line('(Z) '))

local priority_g_z = lex:tag(lexer.LIST .. '.priority.g_z', lexer.starts_line(P('(') * lexer.upper * P(') ')))

-- priority A-F can have different styles, G-Z all the same - similar approach as Markor Android app https://github.com/gsantner/markor/blob/master/app/src/main/java/net/gsantner/markor/format/todotxt/TodoTxtBasicSyntaxHighlighter.java#L13
-- in theme properties:
--      scintillua.styles.list.priority.a
--      scintillua.styles.list.priority.b
--      scintillua.styles.list.priority....
-- Example
--      scintillua.styles.list.priority.a=fore:$(scintillua.colors.red),bold
--      scintillua.styles.list.priority.b=fore:$(scintillua.colors.orange),bold
--      scintillua.styles.list.priority.c=fore:$(scintillua.colors.green),bold
--      scintillua.styles.list.priority.d=fore:$(scintillua.colors.blue),bold
--      scintillua.styles.list.priority.e=fore:$(scintillua.colors.purple),bold
--      scintillua.styles.list.priority.f=fore:$(scintillua.colors.dark_grey),bold
--      scintillua.styles.list.priority.g_z=fore:$(scintillua.colors.grey),bold
lex:add_rule('priority',
                priority_a +
                priority_b +
                priority_c +
                priority_d +
                priority_e +
                priority_f +
                priority_g_z
)

-- priority A-Z can have different styles
--lex:add_rule('priority', priority_a + priority_b + priority_c + priority_d + priority_e + priority_f + priority_g + priority_h + priority_i + priority_j + priority_k + priority_l + priority_m + priority_n + priority_o + priority_p + priority_q + priority_r + priority_s + priority_t + priority_u + priority_v + priority_w + priority_x + priority_y + priority_z)
--lex:add_rule('priority',
--                priority_a +
--                priority_b +
--                priority_c +
--                priority_d +
--                priority_e +
--                priority_f +
--                priority_g +
--                priority_h +
--                priority_i +
--                priority_j +
--                priority_k +
--                priority_l +
--                priority_m +
--                priority_n +
--                priority_o +
--                priority_p +
--                priority_q +
--                priority_r +
--                priority_s +
--                priority_t +
--                priority_u +
--                priority_v +
--                priority_w +
--                priority_x +
--                priority_y +
--                priority_z
--)


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
