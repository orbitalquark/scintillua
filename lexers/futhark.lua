-- Copyright 2026 Marina (@kala-telo on github). See LICENSE.
-- Futhark LPeg lexer.
-- Reference: https://futhark.readthedocs.io/en/stable/language-reference.html

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- Types.
lex:add_rule('type', lex:tag(lexer.TYPE, lex:word_match(lexer.TYPE) + '#' * lexer.word))

-- Functions.
lex:add_rule('functions', lex:tag(lexer.FUNCTION, lex:word_match(lexer.FUNCTION)))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))

-- Strings.
local sq_str = lexer.range("'")
local dq_str = lexer.range('"')
lex:add_rule('string', lex:tag(lexer.STRING, sq_str + dq_str))

-- Comments.
lex:add_rule('comment', lex:tag(lexer.COMMENT, lexer.to_eol('--')))

-- Numbers.
local integer = S('+-')^-1 * (lexer.hex_num + lexer.bin_num + lexer.dec_num) *
	lexer.word_match('i8 i16 i32 i64 u8 u16 u32 u64')^-1
local float = lexer.float * lexer.word_match('f16 f32 f64')^-1
lex:add_rule('number', lex:tag(lexer.NUMBER, float + integer))

-- Attributes.
lex:add_rule('preprocessor', lex:tag(lexer.PREPROCESSOR, '#' * lexer.range('[', ']', true)))

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('+-*/%^=<>,.{}[]():`|')))

lex:set_word_list(lexer.KEYWORD, {
	'true', 'false', 'if', 'then', 'else', 'def', 'let', 'loop', 'in', 'val', 'for', 'do', 'with',
	'local', 'open', 'include', 'import', 'type', 'entry', 'module', 'while', 'assert', 'match',
	'case'
})

lex:set_word_list(lexer.TYPE, {
	'i8', 'i16', 'i32', 'i64', 'u8', 'u16', 'u32', 'u64', 'f16', 'f32', 'f64', 'bool'
})

lex:set_word_list(lexer.FUNCTION, {
	-- /prelude/prelude
	'r32', 't32', 'r64', 't64', 'not', 'opaque', 'trace', 'break',

	-- /prelude/soacs
	'map', 'map1', 'map2', 'map3', 'map4', 'map5', 'reduce', 'reduce_comm', 'hist', 'reduce_by_index',
	'reduce_by_index_2d', 'reduce_by_index_3d', 'scan', 'all', 'any', 'spread', 'scatter', 'exscan',
	'scatter_2d', 'scatter_3d', 'filter', 'partition', 'partition2', 'flatmap', 'flatmap',

	-- /prelude/array
	'length', 'null', 'head', 'last', 'tail', 'init', 'take', 'drop', 'sized', 'split', 'reverse',
	'concat', 'iota', 'indices', 'rotate', 'replicate', 'rep', 'copy', 'manifest', 'flatten',
	'flatten_3d', 'flatten_4d', 'unflatten', 'unflatten_3d', 'unflatten_4d', 'transpose', 'and', 'or',
	'foldl', 'foldr', 'tabulate', 'tabulate_2d', 'tabulate_3d',

	-- /prelude/zip
	'zip', 'zip2', 'zip3', 'zip4', 'zip5', 'unzip', 'unzip2', 'unzip3', 'unzip4', 'unzip5',

	-- /prelude/functional
	'flip', 'curry', 'uncurry', 'const', 'id', 'iterate', 'iterate_until', 'iterate_while',

	-- /prelude/ad
	'jvp2', 'vjp2', 'jmp2', 'mjp2', 'jvp', 'vjp', 'jmp', 'mjp', 'with_vjp', 'with_vjp_tape'
})

return lex
