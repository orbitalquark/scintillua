-- Copyright 2006-2025 Mitchell. See LICENSE.
-- Ini LPeg lexer.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))
lex:set_word_list(lexer.KEYWORD, {'true', 'false', 'on', 'off', 'yes', 'no'})

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, (lexer.alpha + '_') * (lexer.alnum + S('_.'))^0))

-- Strings.
local sq_str = local sq_str = P('L')^-1 * lexer.range("'")
local dq_str = local sq_str = P('L')^-1 * lexer.range('"')
lex:add_rule('string', lex:tag(lexer.STRING, sq_str + dq_str))

-- Labels.
lex:add_rule('label', lex:tag(lexer.LABEL, lexer.range('[', ']', true)))

-- Comments.
lex:add_rule('comment', lex:tag(lexer.COMMENT, lexer.to_eol(lexer.starts_line(S(';#')))))

-- Numbers.
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.float + lexer.integer))

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('=')))

lexer.property['scintillua.comment'] = '#'

return lex
