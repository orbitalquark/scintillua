-- Copyright 2015-2022 Alejandro Baez (https://keybase.io/baez). See LICENSE.
-- Rust LPeg lexer.

local lexer = lexer
local P, S = lpeg.P, lpeg.S
local C, Cmt = lpeg.C, lpeg.Cmt

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- Macro names.
lex:add_rule('macro', lex:tag(lexer.FUNCTION, lexer.word * S("!")))

-- Library types
lex:add_rule('library', lex:tag(lexer.LABEL, lexer.upper * (lexer.lower + lexer.dec_num)^1))

-- Numbers.
local identifier = P('r#')^-1 * lexer.word
local digit = lexer.digit
local decimal_literal = digit * (digit + '_')^0
local function integer_suffix(digit) return P('_')^0 * digit * (digit + '_')^0 end
local function opt_cap(patt) return C(patt^-1) end
local float = decimal_literal *
  (Cmt(opt_cap('.' * decimal_literal) * opt_cap(S('eE') * S('+-')^-1 * integer_suffix(digit)) *
    opt_cap(P('f32') + 'f64'), function(input, index, decimals, exponent, type)
    return decimals ~= "" or exponent ~= "" or type ~= ""
  end) + '.' * -(S('._') + identifier))
local function prefixed_integer(prefix, digit) return P(prefix) * integer_suffix(digit) end
local bin = prefixed_integer('0b', S('01'))
local oct = prefixed_integer('0o', lpeg.R('07'))
local hex = prefixed_integer('0x', lexer.xdigit)
local integer = (bin + oct + hex + decimal_literal) *
  (S('iu') * (P('8') + '16' + '32' + '64' + '128' + 'size'))^-1
lex:add_rule('number', lex:tag(lexer.NUMBER, float + integer))

-- Types.
lex:add_rule('type', lex:tag(lexer.TYPE, lex:word_match(lexer.TYPE)))

-- Lifetime annotation
lex:add_rule('lifetime', lex:tag(lexer.OPERATOR, S('<&') * P("'")))

-- Strings.
local sq_str = P('b')^-1 * lexer.range("'", true)
local dq_str = P('b')^-1 * lexer.range('"')
local raw_str = Cmt(P('b')^-1 * P('r') * C(P('#')^0) * '"', function(input, index, hashes)
  local _, e = input:find('"' .. hashes, index, true)
  return (e or #input) + 1
end)
lex:add_rule('string', lex:tag(lexer.STRING, sq_str + dq_str + raw_str))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, identifier))

-- Comments.
local line_comment = lexer.to_eol('//', true)
local block_comment = lexer.range('/*', '*/', false, false, true)
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))

-- Attributes.
lex:add_rule('preprocessor', lex:tag(lexer.PREPROCESSOR, '#' * lexer.range('[', ']', true)))

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('+-/*%<>!=`^~@&|?#~:;,.()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.OPERATOR, '(', ')')
lex:add_fold_point(lexer.OPERATOR, '{', '}')

-- https://doc.rust-lang.org/std/#keywords
lex:set_word_list(lexer.KEYWORD, {
  'SelfTy',
  'as',
  'async',
  'await',
  'break',
  'const',
  'continue',
  'crate',
  'dyn',
  'else',
  'enum',
  'extern',
  'false',
  'fn',
  'for',
  'if',
  'impl',
  'in',
  'let',
  'loop',
  'match',
  'mod',
  'move',
  'mut',
  'pub',
  'ref',
  'return',
  'self',
  'static',
  'struct',
  'super',
  'trait',
  'true',
  'type',
  'union',
  'unsafe',
  'use',
  'where',
  'while',
})

lex:set_word_list(lexer.TYPE, {
  'bool isize usize char str u8 u16 u32 u64 u128 i8 i16 i32 i64 i128 f32 f64'
})

lexer.property['scintillua.comment'] = '//'

return lex
