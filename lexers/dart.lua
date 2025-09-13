-- Copyright 2013-2025 Mitchell. See LICENSE.
-- Dart LPeg lexer.
-- Written by Brian Schott (@Hackerpilot on Github).
-- Migrated by Jamie Drinkell

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))
-- Built-ins.
lex:add_rule('builtin', lex:tag(lexer.CONSTANT, lex:word_match(lexer.CONSTANT)))
-- Types.
lex:add_rule('type', lex:tag(lexer.TYPE, lex:word_match(lexer.TYPE)))

-- Strings.
local sq_str = S('r')^-1 * lexer.range("'", true)
local dq_str = S('r')^-1 * lexer.range('"', true)
local tq_str = S('r')^-1 * (lexer.range("'''") + lexer.range('"""'))
lex:add_rule('string', lex:tag(lexer.STRING, tq_str + sq_str + dq_str))

-- Functions.
lex:add_rule('function', lex:tag(lexer.FUNCTION, lexer.word) * #(lexer.space^0 * '('))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))

-- Comments.
local line_comment = lexer.to_eol('//', true)
local block_comment = lexer.range('/*', '*/')
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number))

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('#?=!<>+-*$/%&|^~.,;()[]{}')))

-- Annotations.
lex:add_rule('annotation', lex:tag(lexer.ANNOTATION, '@' * lexer.word^1))

-- Fold points (add for most bracket pairs due to Flutter's usual formatting).
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.OPERATOR, '(', ')')
lex:add_fold_point(lexer.OPERATOR, '[', ']')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')

lex:set_word_list(lexer.KEYWORD, {
	'assert', 'break', 'case', 'catch', 'class', 'const', 'continue', 'default', 'do', 'else', 'enum',
	'extends', 'false', 'final', 'finally', 'for', 'if', 'in', 'is', 'new', 'rethrow', 'return',
	'super', 'switch', 'this', 'throw', 'true', 'try', 'var', 'while', 'with', 'import', 'await',
	'async', 'required'
})

lex:set_word_list(lexer.CONSTANT, {
	'abstract', 'as', 'dynamic', 'export', 'external', 'factory', 'get', 'implements', 'import',
	'library', 'operator', 'part', 'set', 'static', 'typedef'
})

lex:set_word_list(lexer.TYPE, {
	'int', 'double', 'String', 'bool', 'Function', 'List', 'Set', 'Map', 'null', 'Future', 'Stream',
	'Iterable', 'dynamic', 'Object', 'Null', 'void'
})

lexer.property['scintillua.comment'] = '//'

return lex
