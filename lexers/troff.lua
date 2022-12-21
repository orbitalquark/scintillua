-- Copyright 2015-2017 David B. Lamkins <david@lamkins.net>. See LICENSE.
-- man/roff LPeg lexer.

local lexer = lexer
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new(...)

-- Registers and groff's structured programming.
lex:add_rule('keywords', lex:tag(lexer.KEYWORD, (lexer.starts_line('.') * lexer.space^0 * (P('while') + P('break') + P('continue') + P('nr') + P('rr') + P('rnn') + P('aln') + P('\\}'))) + P('\\{')))

-- Markup.
lex:add_rule('escape_sequences', lex:tag(lexer.VARIABLE,
	P('\\') * ((P('s') * S('+-')) + S('*fgmnYV')) *
	(P('(') * 2 + lexer.range('[', ']')))

lex:add_rule('headings', lex:tag(lexer.NUMBER, lexer.starts_line('.') * lexer.space^0 * (S('STN') * P('H')) * lexer.space * lexer.nonnewline^0)
lex:add_rule('man_alignment', lex:tag(lexer.KEYWORD, lexer.starts_line('.') * lexer.space^0 * (P('br') + P('DS') + P('RS') + P('RE') + P('PD') + P('PP')) * lexer.space))
lex:add_rule('font', lex:tag(lexer.VARIABLE, lexer.starts_line('.') * lexer.space^0 * (P('B') * P('R')^-1 + P('I') * S('PR')^-1) * lexer.space))

-- Lowercase troff macros are plain macros (like .so or .nr).
lex:add_rule('troff_plain_macros', lex:tag(lexer.VARIABLE, lexer.starts_line('.') * lexer.space^0 * lexer.lower^1)
lex:add_rule('any_macro', lex:tag(lexer.PREPROCESSOR, lexer.starts_line('.') * lexer.space^0 * (lexer.any-lexer.space)^0)
lex:add_rule('comment', lex:tag(lexer.COMMENT, (lexer.starts_line('.\\"') + P('\\"') + P('\\#')) * lexer.nonnewline^0)
lex:add_rule('string', lex:tag(lexer.STRING, lexer.range('"', true))

-- Usually used by eqn, and mandoc in some way.
lex:add_rule('in_dollars', lex:tag(lexer.EMBEDDED, lexer.range('$', false, false))

return lex
