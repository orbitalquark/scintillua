-- Copyright 2026 Michiel van den Heuvel. See LICENSE.
-- HCL2 LPeg lexer.
-- Reference: https://developer.hashicorp.com/nomad/docs/reference/hcl2
local lexer = lexer
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new(...)

local utf8_char = lpeg.utfR and lpeg.utfR(0x7F, 0x10FFFF) or R('\128\255') ^ 1
local id = (lexer.alpha + '_' + utf8_char) * (lexer.alnum + S('_-') + utf8_char) ^ 0

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- Functions.
lex:add_rule('function', lex:tag(lexer.FUNCTION, id) * #(lexer.space ^ 0 * '('))

-- Constants.
lex:add_rule('constant', lex:tag(lexer.CONSTANT_BUILTIN, lex:word_match(lexer.CONSTANT_BUILTIN)))

-- Identifiers
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, id))

-- Strings.
local heredoc = '<<' * P(function(input, index)
	local _, e, minus, delimiter = input:find('^(%-?)([%w_]+)[\r\n]+', index)
	if not delimiter then return nil end
	-- If the starting delimiter of a here-doc begins with "-", then spaces are allowed to come
	-- before the closing delimiter.
	_, e = input:find((minus == '' and '[\r\n]+' or '[\r\n]+[ \t]*') .. delimiter .. '[\r\n]+', e)
	return e and e + 1 or #input + 1
end)
lex:add_rule('string', lex:tag(lexer.STRING, lexer.range('"', true) + heredoc))

-- Comments.
local comment = lexer.to_eol(P('#') + '//')
local block_comment = lexer.range('/*', '*/')
lex:add_rule('comment', lex:tag(lexer.COMMENT, comment + block_comment))

-- Numbers.
local exp = S('eE') * S('+-') ^ -1 * lexer.digit ^ 1
local number = lexer.digit ^ 1 * ('.' * lexer.digit ^ 1) ^ -1 * exp ^ -1
lex:add_rule('number', lex:tag(lexer.NUMBER, number))

-- Operators.
local operator = P('...') + '=>' + '==' + '!=' + '<=' + '>=' + '&&' + '||' +
	                 S('+-*/%!<>=?:,.()[]{}')
lex:add_rule('operator', lex:tag(lexer.OPERATOR, operator))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '(', ')')
lex:add_fold_point(lexer.OPERATOR, '[', ']')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')

-- Word lists.
lex:set_word_list(lexer.KEYWORD, 'for in if')
lex:set_word_list(lexer.CONSTANT_BUILTIN, 'true false null')

lexer.property['scintillua.comment'] = '#'

return lex
