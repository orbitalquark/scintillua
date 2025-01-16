-- Copyright 2006-2025 Mitchell. See LICENSE.
-- Text LPeg lexer.

local lexer = lexer

local lex = lexer.new(...)

lex:add_rule('text', lexer.token(lexer.DEFAULT, (1 - lexer.space)^1))

return lex
