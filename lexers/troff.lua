-- Copyright 2015-2017 David B. Lamkins <david@lamkins.net>. See LICENSE.
-- man/roff LPeg lexer.

local lexer = lexer
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new(...)

-- Registers and groff's structured programming.
lex:add_rule('keywords', lex:tag(lexer.KEYWORD, (lexer.starts_line('.') * lexer.space^0 * (P('while') + P('break') + P('continue') + P('nr') + P('rr') + P('rnn') + P('aln') + P('\\}'))) + P('\\{'))

-- Markup.
lex:add_rule('escape_sequences', lex:tag(lexer.VARIABLE,
	P('\\') * ((P('s') * S('+-')) + S('*fgmnYV') + P("")) *
	(P('(') * 2 + P('[') * (lexer.any-P(']'))^0 * P(']') + 1))

lex:add_rule('headings', lex:tag(lexer.NUMBER, P('.') * (S('STN') * P('H')) * (lexer.space + P("\n")) * lexer.nonnewline^0)
lex:add_rule('man_alignment', lex:tag(lexer.KEYWORD, lexer.starts_line('.'), (P('br') + P('DS') + P('RS') + P('RE') + P('PD')) * (lexer.space + P("\n")))
lex:add_rule('font', lex:tag(lexer.VARIABLE, (P('.B') * P('R')^-1 + P('.I') * S('PR')^-1 + P('.PP')) * (lexer.space + P("\n")))

-- Lowercase troff macros are plain macros (like .so or .nr).
lex:add_rule('troff_plain_macros', lex:tag(lexer.VARIABLE, lexer.starts_line('.') * lexer.space^0 * lexer.lower^1)
lex:add_rule('any_macro', lex:tag(lexer.PREPROCESSOR, lexer.starts_line('.') * lexer.space^0 * (lexer.any-lexer.space)^0)
lex:add_rule('comment', lex:tag(lexer.COMMENT, (lexer.starts_line('.\\"') + P('\\"') + P('\\#')) * lexer.nonnewline^0)
lex:add_rule('string', lex:tag(lexer.STRING, P('"') * (lexer.nonnewline-P('"'))^0 * (P('"') + (P("\n"))))

-- Usually used by eqn, and mandoc in some way.
lex:add_rule('in_dollars', lex:tag(lexer.EMBEDDED, P('$') * (lexer.any - P('$'))^0 * P('$'))

return lex
