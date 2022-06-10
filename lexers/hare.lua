-- Copyright 2021-2022 Mitchell. See LICENSE.
-- Hare LPeg lexer
-- https://harelang.org
-- Contributed by Qiu

local l = require('lexer')
local token, word_match = l.token, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = {_NAME = 'hare'}

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local line_comment = '//' * l.nonnewline_esc^0
local comment = token(l.COMMENT, line_comment)

-- Strings.
local dq_str = l.delimited_range('"')
local raw_str = l.delimited_range('`')
local string = token(l.STRING, dq_str + raw_str)

-- Numbers.
local number = token(l.NUMBER, l.float + l.integer)

-- Functions.
local func = token(l.FUNCTION, word_match{
  'len', 'alloc', 'free', 'assert',
  'abort', 'size', 'append', 'insert', 'delete',
  'vastart', 'vaarg', 'vaend'
})

-- Keywords.
local keyword = token(l.KEYWORD, word_match{
  'as', 'break', 'case', 'const', 'continue',
  'def', 'defer', 'else', 'export', 'false', 'fn',
  'for', 'if', 'is', 'let', 'match', 'null',
  'nullable', 'return', 'static', 'struct',
  'switch', 'true', 'type',  'use', 'yield'
})

-- Types.
local type = token(l.TYPE, word_match{
  'bool', 'enum', 'f32', 'f64', 'i16', 'i32',
  'i64', 'i8', 'int', 'u16', 'u32', 'u64', 'u8',
  'uint', 'uintptr', 'union', 'void', 'rune',
  'str', 'char'
})

-- at rule.
local at_rule = token('at_rule', P('@') * word_match{
  'noreturn', 'offset', 'init', 'fini', 'test', 'symbol'
})

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

-- Operators.
local operator = token(l.OPERATOR, S('+-/*%^!=&|?:;,.()[]{}<>'))

M._rules = {
  {'whitespace', ws},
  {'keyword', keyword},
  {'function', func},
  {'type', type},
  {'identifier', identifier},
  {'comment', comment},
  {'number', number},
  {'string', string},
  {'operator', operator},
  {'at_rule', at_rule},
}

M._tokenstyles = {
  at_rule = l.STYLE_PREPROCESSOR
}

M._foldsymbols = {
  _patterns = {'[{}]', '//'},
  [l.OPERATOR] = {['{'] = 1, ['}'] = -1},
  [l.COMMENT] = {['//'] = l.fold_line_comments('//')}
}

return M
