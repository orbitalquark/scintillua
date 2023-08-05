-- Copyright 2021-2023 Mitchell. See LICENSE.
-- Hare LPeg lexer
-- https://harelang.org
-- Contributed by Qiu

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('hare')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match{
  'as', 'break', 'case', 'const', 'continue', 'def', 'defer', 'else', 'export', 'false', 'fn',
  'for', 'if', 'is', 'let', 'match', 'null', 'nullable', 'return', 'static', 'struct', 'switch',
  'true', 'type', 'use', 'yield'
}))

-- Functions.
local size_builtin = 'size' * #(lexer.space^0 * '(')
lex:add_rule('function', token(lexer.FUNCTION, word_match{
  'abort', 'align', 'alloc', 'append', 'assert', 'cap', 'delete', 'free', 'insert', 'len', 'offset',
  'vaarg', 'vaend', 'vastart'
} + size_builtin))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match{
  'bool', 'enum', 'f32', 'f64', 'i16', 'i32', 'i64', 'i8', 'int', 'rune', 'size', 'str', 'u16',
  'u32', 'u64', 'u8', 'uint', 'uintptr', 'union', 'valist', 'void'
}))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
local sq_str = lexer.range("'", true)
local dq_str = lexer.range('"')
local raw_str = lexer.range('`')
lex:add_rule('string', token(lexer.STRING, sq_str + dq_str + raw_str))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, lexer.to_eol('//')))

-- Numbers.
local integer_suffix = word_match{
  "i", "u", "z", "i8", "i16", "i32", "i64", "u8", "u16", "u32", "u64"
}
local float_suffix = word_match{"f32", "f64"}
local suffix = integer_suffix + float_suffix

local bin_num = '0b' * R('01')^1 * -lexer.xdigit
local oct_num = '0o' * R('07')^1 * -lexer.xdigit
local hex_num = '0x' * lexer.xdigit^1
local integer_literal = S('+-')^-1 *
  ((hex_num + oct_num + bin_num) * integer_suffix^-1 + lexer.dec_num * suffix^-1)
local float_literal = lexer.float * float_suffix^-1
lex:add_rule('number', token(lexer.NUMBER, integer_literal + float_literal))

-- Error assertions
lex:add_rule('error_assert', token('error_assert', lpeg.B(')') * P('!')))
lex:add_style('error_assert', lexer.styles.error)

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('+-/*%^!=&|?~:;,.()[]{}<>')))

-- Attributes.
lex:add_rule('attribute', token(lexer.ANNOTATION, '@' * lexer.word))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')

lexer.property['scintillua.comment'] = '//'

return lex
