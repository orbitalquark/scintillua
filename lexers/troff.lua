-- Copyright 2015-2017 David B. Lamkins <david@lamkins.net>. See LICENSE.
-- man/roff LPeg lexer.

local lexer = require('lexer')
local token, word_match = l.token, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('troff')

-- Whitespace.
local whitespace = token(l.WHITESPACE, l.space^1)

-- Markup.
lex:add_rule('keywords', token(l.KEYWORD, (l.starts_line('.') * l.space^0 * (P('while') + P('break') + P('continue') + P('nr') + P('rr') + P('rnn') + P('aln') + P('\\}'))) + P('\\{'))

lex:add_rule('escape_sequences', token(l.VARIABLE,
	P('\\') * ((P('s') * S('+-')) + S('*fgmnYV') + P("")) *
	(P('(') * 2 + P('[') * (l.any-P(']'))^0 * P(']') + 1))

lex:add_rule('headings', token(l.NUMBER, P('.') * (S('STN') * P('H')) * (l.space + P("\n")) * l.nonnewline^0)

lex:add_rule('alignment', token(l.KEYWORD, l.starts_line('.'), (P('br') + P('DS') + P('RS') + P('RE') + P('PD')) * (l.space + P("\n")))

lex:add_rule('font', token(l.VARIABLE, (P('.B') * P('R')^-1 + P('.I') * S('PR')^-1 + P('.PP')) * (l.space + P("\n")))

lex:add_rule('troff_plain_macros', token(l.VARIABLE, l.starts_line('.') * l.space^0 * l.lower^1)
lex:add_rule('any_macro', token(l.PREPROCESSOR, l.starts_line('.') * l.space^0 * (l.any-l.space)^0)
lex:add_rule('comment', token(l.COMMENT, (l.starts_line('.\\"') + P('\\"') + P('\\#')) * l.nonnewline^0)
lex:add_rule('quoted', token(l.STRING, P('"') * (l.nonnewline-P('"'))^0 * (P('"') + (P("\n"))))
-- Usually used by eqn, and mandoc in some way.
lex:add_rule('in_dollars', token(l.EMBEDDED, P('$') * (l.any - P('$'))^0 * P('$'))

return M
