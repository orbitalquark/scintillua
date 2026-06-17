-- Copyright 2026 Artur Ugnivenko. See LICENSE.
-- Odin LPeg lexer.

-- References:
-- https://odin-lang.org/spec/grammar/
-- https://pkg.odin-lang.org/base/builtin/

local lexer = lexer
local token, word_match = lexer.token, lexer.word_match
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Rules.
local sq_str = P('L')^-1 * lexer.range("'")
local dq_str = P('L')^-1 * lexer.range('"')
local ml_str = P('L')^-1 * lexer.range('`')
lex:add_rule('string', lex:tag(lexer.STRING, sq_str + dq_str + ml_str))

local comment = lexer.to_eol('//', true)
local block_comment = lexer.range('/*', '*/')
lex:add_rule('comment', lex:tag(lexer.COMMENT, comment + block_comment))

local directive = lex:tag(lexer.PREPROCESSOR, '#' * lexer.word)
lex:add_rule('directive', directive)

local attribute = lex:tag(lexer.PREPROCESSOR,
	'@(' * (lexer.word + lexer.number + lexer.range('"') + lexer.range("'") + P('=') + P(' '))^0 * ')'
)
lex:add_rule('attribute', attribute)

lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))
lex:add_rule('type', lex:tag(lexer.TYPE, lex:word_match(lexer.TYPE)))
lex:add_rule('constant', lex:tag(lexer.CONSTANT, lex:word_match(lexer.CONSTANT)))
lex:add_rule('function', lex:tag(lexer.FUNCTION, lex:word_match(lexer.FUNCTION)))
lex:modify_rule('constant', lex:get_rule('constant') + lex:word_match(lexer.VARIABLE_BUILTIN))
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number))
lex:add_rule('operator', lex:tag(lexer.OPERATOR, '..' + S('+-/*%<>!=^&|?~:;,.()[]{}')))

local identifier = lex:tag(lexer.IDENTIFIER, lexer.word)
local function_call = lex:tag(lexer.FUNCTION, lexer.word * #P('('))
lex:add_rule('function_call', function_call)
lex:add_rule('identifier', identifier)

lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')

-- Word lists.
lex:set_word_list(lexer.KEYWORD, {
	'asm', 'auto_cast', 'bit_field', 'bit_set', 'break',
	'case', 'cast', 'continue', 'defer', 'distinct',
	'do', 'dynamic', 'else', 'fallthrough', 'for',
	'foreign', 'if', 'import', 'in', 'map', 'matrix', 'not_in',
	'of_break', 'or_continue', 'or_else', 'or_return', 'package',
	'proc', 'return', 'switch', 'transmute', 'typeid',
	'using', 'when', 'where',
	'enum', 'struct', 'union',
})

lex:set_word_list(lexer.TYPE, {
	'any',
	'b8', 'b16', 'b32', 'b64',
	'bool',
	'byte',
	'complex32', 'complex64', 'complex128',
	'cstring', 'cstring16',
	'f16', 'f16le', 'f16be',
	'f32', 'f32le', 'f32be',
	'f64', 'f64le', 'f64be',
	'i8',
	'i16', 'i16le', 'i16be',
	'i32', 'i32le', 'i32be',
	'i64', 'i64le', 'i64be',
	'int',
	'quaternion64', 'quaternion128', 'quaternion256',
	'rawptr',
	'rune', 'string', 'string16',
	'typeid',
	'u8',
	'u16', 'u16le', 'u16be',
	'u32', 'u32le', 'u32be',
	'u64', 'u64le', 'u64be',
	'uint', 'uintptr',
})

lex:set_word_list(lexer.CONSTANT, {
	'false', 'true', 'nil',
	'ODIN_ARCH', 'ODIN_BUILD_MODE', 'ODIN_COMPILE_TIMESTAMP',
	'ODIN_DEBUG', 'ODIN_DEFAULT_TO_NIL_ALLOCATOR',
	'ODIN_DEFAULT_TO_PANIC_ALLOCATOR', 'ODIN_DISABLE_ASSERT',
	'ODIN_ENDIAN', 'ODIN_ERROR_POS_STYLE', 'ODIN_NO_CRT',
	'ODIN_NO_ENTRY_POINT', 'ODIN_NO_RTTI', 'ODIN_OS',
	'ODIN_PLATFORM_SUBTARGET', 'ODIN_ROOT', 'ODIN_VENDOR',
	'ODIN_VERSION', 'ODIN_WINDOWS_SUBSYSTEM',
})

lex:set_word_list(lexer.FUNCTION, {
	'abs', 'align_of', 'cap', 'clamp', 'complex', 'compress_values',
	'conj', 'expand_values', 'imag', 'jmag', 'kmag', 'len', 'max',
	'min', 'offset_of', 'offset_of_by_string', 'offset_of_member',
	'offset_of_selector', 'quaternion', 'raw_data', 'real', 'size_of',
	'soa_unzip', 'soa_zip', 'swizzle', 'type_info_of', 'type_of',
	'typeid_of',
})

lex:set_word_list(lexer.VARIABLE_BUILTIN, {
	'context', 'runtime',
})

return lex
