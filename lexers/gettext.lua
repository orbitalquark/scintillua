-- Copyright 2006-2025 Mitchell. See LICENSE.
-- Gettext LPeg lexer.

local lexer = lexer
local token, word_match = lexer.token, lexer.word_match
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match(
	'msgid msgid_plural msgstr fuzzy c-format no-c-format', true)))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Variables.
lex:add_rule('variable', token(lexer.VARIABLE, S('%$@') * lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.range('"', true)))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, lexer.to_eol('#' * S(': .~'))))

lexer.property['scintillua.comment'] = '#'

return lex
