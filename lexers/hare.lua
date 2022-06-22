-- Copyright 2021-2022 Mitchell. See LICENSE.
-- Hare LPeg lexer
-- https://harelang.org
-- Contributed by Qiu

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('hare')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Comments.
local line_comment = '//' * lexer.nonnewline_esc^0
lex:add_rule('comment', token(lexer.COMMENT, line_comment))

-- Strings.
local dq_str = lexer.range('"')
local raw_str = lexer.range('`')
lex:add_rule('string', token(lexer.STRING, dq_str + raw_str))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Functions.
lex:add_rule('keyword', token(lexer.FUNCTION, word_match(
  'len', 'alloc', 'free', 'assert', 'abort', 
  'size', 'append', 'insert', 'delete', 'vastart', 
  'vaarg', 'vaend'
)))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match(
  'as', 'break', 'case', 'const', 'continue',
  'def', 'defer', 'else', 'export', 'false', 'fn',
  'for', 'if', 'is', 'let', 'match', 'null',
  'nullable', 'return', 'static', 'struct',
  'switch', 'true', 'type',  'use', 'yield'
)))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match(
  'bool', 'enum', 'f32', 'f64', 'i16', 'i32',
  'i64', 'i8', 'int', 'u16', 'u32', 'u64', 'u8',
  'uint', 'uintptr', 'union', 'void', 'rune',
  'str', 'char'
)))

-- at rule.
lex:add_rule('at_rule', token('at_rule', '@' * word_match(
  'noreturn', 'offset', 'init', 'fini', 'test', 'symbol'
)))
lex:add_style('at_rule', lexer.styles.preprocessor)

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('+-/*%^!=&|?:;,.()[]{}<>')))

lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '//')

return lex
