-- Copyright 2006-2022 Mitchell. See LICENSE.
-- C++ LPeg lexer.

local lexer = require('lexer')
local word_match = lexer.word_match
local P, S = lpeg.P, lpeg.S

local lex = lexer.new('cpp')

-- Whitespace.
local ws = lex:tag(lexer.WHITESPACE, lexer.space^1)
lex:add_rule('whitespace', ws)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, word_match{
  'asm', 'auto', 'break', 'case', 'catch', 'class', 'const', 'const_cast', 'continue', 'default',
  'delete', 'do', 'dynamic_cast', 'else', 'explicit', 'export', 'extern', 'false', 'for', 'friend',
  'goto', 'if', 'inline', 'mutable', 'namespace', 'new', 'operator', 'private', 'protected',
  'public', 'register', 'reinterpret_cast', 'return', 'sizeof', 'static', 'static_cast', 'switch',
  'template', 'this', 'throw', 'true', 'try', 'typedef', 'typeid', 'typename', 'using', 'virtual',
  'volatile', 'while',
  -- Operators.
  'and', 'and_eq', 'bitand', 'bitor', 'compl', 'not', 'not_eq', 'or', 'or_eq', 'xor', 'xor_eq',
  -- C++11.
  'alignas', 'alignof', 'constexpr', 'decltype', 'final', 'noexcept', 'override', 'static_assert',
  'thread_local'
}))

-- Types.
lex:add_rule('type', lex:tag(lexer.TYPE, word_match{
  'bool', 'char', 'double', 'enum', 'float', 'int', 'long', 'short', 'signed', 'struct', 'union',
  'unsigned', 'void', 'wchar_t',
  -- C++11.
  'char16_t', 'char32_t', 'nullptr'
}))

-- Strings.
local sq_str = P('L')^-1 * lexer.range("'", true)
local dq_str = P('L')^-1 * lexer.range('"', true)
lex:add_rule('string', lex:tag(lexer.STRING, sq_str + dq_str))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))

-- Comments.
local line_comment = lexer.to_eol('//', true)
local block_comment = lexer.range('/*', '*/')
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
local dec = lexer.digit^1 * ("'" * lexer.digit^1)^0
local hex = '0' * S('xX') * lexer.xdigit^1 * ("'" * lexer.xdigit^1)^0
local bin = '0' * S('bB') * S('01')^1 * ("'" * S('01')^1)^0 * -lexer.xdigit
local integer = S('+-')^-1 * (hex + bin + dec)
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.float + integer))

-- Preprocessor.
local include = lex:tag(lexer.PREPROCESSOR, '#' * S('\t ')^0 * 'include') *
  (ws * lex:tag(lexer.STRING, lexer.range('<', '>', true)))^-1
local preproc = lex:tag(lexer.PREPROCESSOR, '#' * S('\t ')^0 *
  word_match('define elif else endif error if ifdef ifndef import line pragma undef using warning'))
lex:add_rule('preprocessor', include + preproc)

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('+-/*%<>!=^&|?~:;,.()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.PREPROCESSOR, 'if', 'endif')
lex:add_fold_point(lexer.PREPROCESSOR, 'ifdef', 'endif')
lex:add_fold_point(lexer.PREPROCESSOR, 'ifndef', 'endif')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('//'))

return lex
