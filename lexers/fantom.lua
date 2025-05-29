-- Copyright 2018-2025 Simeon Maryasin (MarSoft). See LICENSE.
-- Fantom LPeg lexer.
-- Based on Java LPeg lexer by Mitchell and Vim's Fantom syntax.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- Types.
lex:add_rule('type', lex:tag(lexer.TYPE, lex:word_match(lexer.TYPE)))

-- Functions.
-- lex:add_rule('function', lex:tag(lexer.FUNCTION, lexer.word) * #P('('))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))

-- Strings.
local sq_str = lexer.range("'", true)
local dq_str = lexer.range('"', true)
local bq_str = lexer.range('`', true)
lex:add_rule('string', lex:tag(lexer.STRING, sq_str + dq_str + bq_str))

-- Comments.
local line_comment = lexer.to_eol('//', true)
local block_comment = lexer.range('/*', '*/')
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number * S('LlFfDd')^-1))

-- Operators.
local operators = P('++') + P('--') + P('==') + P('!=') + P('>=') + P('<=') +
	P('&&') + P('||') + P('??') + P('?.') + S('+-/*%<>!=^&|?~:;.()[]{}#')
lex:add_rule('operator', lex:tag(lexer.OPERATOR, operators))


-- Annotations.
lex:add_rule('facet', lex:tag(lexer.ANNOTATION, '@' * lexer.word))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')

-- Word lists
lex:set_word_list(lexer.KEYWORD, {
	'using', 'native', -- external
	'goto', 'void', 'serializable', 'volatile', -- error
	'if', 'else', 'switch', -- conditional
	'do', 'while', 'for', 'foreach', 'each', -- repeat
	'true', 'false', -- boolean
	'null', -- constant
	'this', 'super', -- typedef
	'new', 'is', 'isnot', 'as', -- operator
	'plus', 'minus', 'mult', 'div', 'mod', 'get', 'set', 'slice', 'lshift', 'rshift', 'and', 'or',
	'xor', 'inverse', 'negate', --
	'increment', 'decrement', 'equals', 'compare', -- long operator
	'return', -- stmt
	'static', 'const', 'final', -- storage class
	'virtual', 'override', 'once', -- slot
	'readonly', -- field
	'throw', 'try', 'catch', 'finally', -- exceptions
	'assert', -- assert
	'class', 'enum', 'mixin', 'typedef', -- typedef
	'break', 'continue', -- branch
	'default', 'case', -- labels
	'public', 'internal', 'protected', 'private', 'abstract' -- scope decl
})

lex:set_word_list(lexer.TYPE, {'Void', 'Bool', 'Int', 'Float', 'Decimal',
	'Str', 'Duration', 'Uri', 'Type', 'Range', 'List', 'Map', 'Obj', 'Err', 'Env'
})


lexer.property['scintillua.comment'] = '//'

return lex
