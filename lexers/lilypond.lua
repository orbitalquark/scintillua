-- Copyright 2006-2025 Robert Gieseke. See LICENSE.
-- Lilypond LPeg lexer.
-- TODO Embed Scheme; Notes?, Numbers?

local lexer = lexer
local token, word_match = lexer.token, lexer.word_match
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Keywords, commands.
lex:add_rule('keyword', token(lexer.KEYWORD, '\\' * lexer.word))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.range('"', false, false)))

-- Comments.
-- TODO: block comment.
lex:add_rule('comment', token(lexer.COMMENT, lexer.to_eol('%')))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S("{}'~<>|")))

lexer.property['scintillua.comment'] = '%'

return lex
