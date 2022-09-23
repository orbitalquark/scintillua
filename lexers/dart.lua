-- Copyright 2013-2022 Mitchell. See LICENSE.
-- Dart LPeg lexer.
-- Written by Brian Schott (@Hackerpilot on Github).

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- Built-ins.
lex:add_rule('builtin', lex:tag(lexer.CONSTANT_BUILTIN, lex:word_match(lexer.CONSTANT_BUILTIN)))

-- Strings.
local sq_str = S('r')^-1 * lexer.range("'", true)
local dq_str = S('r')^-1 * lexer.range('"', true)
local tq_str = S('r')^-1 * (lexer.range("'''") + lexer.range('"""'))
lex:add_rule('string', lex:tag(lexer.STRING, tq_str + sq_str + dq_str))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))

-- Comments.
local line_comment = lexer.to_eol('//', true)
local block_comment = lexer.range('/*', '*/', false, false, true)
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number))

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('#?=!<>+-*$/%&|^~.,;()[]{}')))

-- Annotations.
lex:add_rule('annotation', lex:tag(lexer.ANNOTATION, '@' * lexer.word^1))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('//'))

-- Word lists.
lex:set_word_list(lexer.KEYWORD, {
  'assert', 'break', 'case', 'catch', 'class', 'const', 'continue', 'default', 'do', 'else', 'enum',
  'extends', 'false', 'final', 'finally', 'for', 'if', 'in', 'is', 'new', 'null', 'rethrow',
  'return', 'super', 'switch', 'this', 'throw', 'true', 'try', 'var', 'void', 'while', 'with'
})

lex:set_word_list(lexer.CONSTANT_BUILTIN, {
  'abstract', 'as', 'dynamic', 'export', 'external', 'factory', 'get', 'implements', 'import',
  'library', 'operator', 'part', 'set', 'static', 'typedef'
})

lexer.property['scintillua.comment'] = '//'

return lex
