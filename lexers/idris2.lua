-- Copyright 2006-2025 Mitchell. See LICENSE.
-- Idris 2 LPeg lexer.
-- Adapted from Haskell LPeg lexer by Karl Schultheisz.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(..., {fold_by_indentation = true})

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- Types & type constructors.
local word = (lexer.alnum + S("._'"))^0
local op = lexer.punct - S('()[]{}')
lex:add_rule('type', lex:tag(lexer.TYPE, (lexer.upper * word) + (':' * (op^1 - ':'))))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, (lexer.alpha + '_') * word))

-- Strings.
local sq_str = lexer.range("'", true)
local dq_str = lexer.range('"')
lex:add_rule('string', lex:tag(lexer.STRING, sq_str + dq_str))

-- Comments.
local line_comment = lexer.to_eol('--', true)
local block_comment = lexer.range('{-', '-}', false, false, true)
local doc_comment = lexer.to_eol('|||')
lex:add_rule('comment', lex:tag(lexer.COMMENT, doc_comment + line_comment + block_comment))

-- Numbers.
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number_('_')))

-- Pragmas.
local pragma = '%' * lexer.word
lex:add_rule('preprocessor', lex:tag(lexer.PREPROCESSOR, pragma))

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, '..' + op))

lexer.property['scintillua.comment'] = '--'

-- Word lists.
lex:set_word_list(lexer.KEYWORD, {
	'auto', 'autobind', 'case', 'constructor', 'covering', 'data',
	'default', 'do', 'else', 'export', 'failing', 'forall', 'if',
	'implicit', 'import', 'impossible', 'in', 'infix', 'infixl',
	'infixr', 'implementation', 'interface', 'let', 'module',
	'mutual', 'namespace', 'open', 'parameters', 'partial', 'prefix',
	'private', 'proof', 'public', 'record', 'rewrite', 'of', 'then',
	'total', 'typebind', 'using', 'where', 'with', '_'
})

return lex
