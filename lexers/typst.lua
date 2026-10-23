-- Copyright 2026 Jamie Drinkell. See LICENSE.
-- Typst LPeg lexer.
-- Reference: https://typst.app/docs/reference/syntax/

local lexer = lexer
local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new(...)

-- Headings
lex:add_rule('header', lex:tag(lexer.HEADING, lexer.to_eol(lexer.starts_line('=', true))))

-- Lists
lex:add_rule('list', lex:tag(lexer.LIST, lexer.starts_line(S('+-'), true) * S(' \t')))

-- Links
local link_url = -B(P'"') * 'http' * P('s')^-1 * '://' * (lexer.any - lexer.space)^1 +
	('<' * lexer.alpha^2 * ':' * (lexer.any - lexer.space - '>')^1 * '>')
lex:add_rule('link', lex:tag(lexer.LINK, link_url))

-- Comments
local line_comment = lexer.to_eol('//', true)
local block_comment = lexer.range('/*', '*/')
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))

-- Escaped characters (capture them before other rules)
lex:add_rule('escapes', P'\\' * S'*_;#<>$@`')

-- Strong and Emphasis
-- Don't capture use as code mode multiply or import statements.
lex:add_rule('strong',
	lex:tag(lexer.BOLD, lexer.range('*') - (P'* ' + (B(P': ') * '*' * lexer.newline))))
-- Don't capture underscores used in code mode identifiers.
lex:add_rule('em', lex:tag(lexer.ITALIC, lexer.range('_') - ((B('let ') * '_') + ('_' * (S' ,')))))

-- Mathematics
lex:add_rule('maths', lex:tag(lexer.NUMBER, lexer.range('$')))

-- Labels
-- Match provided it's not a code mode more/less than operator
lex:add_rule('label',
	lex:tag(lexer.LABEL, lexer.range('<', '>', true, false, true) - (P'<=' + P'< ')))

-- References
local identifier = lexer.word_utf8 * (S'-.:'^-1 * lexer.word_utf8)^0
lex:add_rule('reference', lex:tag(lexer.REFERENCE, '@' * identifier))

-- Raw Text
local raw_text = lpeg.Cmt(lpeg.C(P('`')^1), function(input, index, bt)
	-- `foo`, ``foo``, ``foo`bar``, `foo``bar` are all allowed.
	local _, e = input:find('[^`]' .. bt .. '%f[^`]', index)
	return (e or #input) + 1
end)
lex:add_rule('raw', lex:tag(lexer.CODE, raw_text))

-- Code Expressions
-- Using rules from: https://typst.app/docs/reference/syntax/#code
local ws = S(' \t')^1
local operators = S'-+*/=!<>'
local func = identifier * #S'(['
lex:add_rule('code_mode', lex:tag(lexer.EMBEDDED, P'#'))

-- Match if after '#' or first word on the line
-- (Basically no-one starts a line in markup uncapitalised)
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, (B'#' * lex:word_match(lexer.KEYWORD)) +
	lexer.starts_line(lex:word_match(lexer.KEYWORD) * #ws, true)))

lex:add_rule('function', lex:tag(lexer.FUNCTION, func))
lex:add_rule('variable', lex:tag(lexer.VARIABLE, B'#' * identifier))

-- Match `else` if after a brace/bracket
lex:add_rule('else', lex:tag(lexer.KEYWORD, B(S']}' * ' ') * P'else'))

-- If after a keyword, it's likely to be situationally in an expression
local likely_expr_post = ws * (
	-- Match if parenthesis/brace/bracket after, e.g. `if (...` or `else {`
	(S'([{')
	-- Match if identifier then operator/brace or ':', e.g. `let ident1 = ...` or `show link: underline`
	+ (identifier * (':' + (ws * (S'({[' + (operators^2 * ws)))))
	-- Match if assignable type, e.g. `while 1 < 2 { ...` or `in "STR" ...`
	+ ('"' + (lexer.number * ws))
	-- Match if "function" is after, e.g. `set page()`
	+ func
)
lex:add_rule('expr', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD) * #likely_expr_post))

lex:add_rule('string',
	lex:tag(lexer.STRING, lexer.range('"') * #(S':,)' + lexer.newline + (ws * S'[{'))))

lex:add_rule('units', lex:tag(lexer.NUMBER, lexer.number * lex:word_match('units')))

-- Lex as a value if after a keyword, operator or being passed into a function.
local likely_value_pre = ((B(P'if ') + B(P'while ') + B(P'for ') + B(P'in ')) +
	(B(S'-–+*/=!<>{(,: ' * ' ') + B('(')))
lex:add_rule('value', lex:tag(lexer.CONSTANT_BUILTIN, likely_value_pre * lex:word_match(lexer.CONSTANT_BUILTIN)))

-- Don't match comma delimited numbers, e.g. "4,200+"
lex:add_rule('numeric', lex:tag(lexer.NUMBER, likely_value_pre *
	(lexer.number - (lexer.number * ',' * lexer.number))))

-- Plain text.
lex:add_rule('word', lex:tag(lexer.DEFAULT, lexer.word_utf8))

local FOLD_HEADER, FOLD_BASE = lexer.FOLD_HEADER, lexer.FOLD_BASE
-- Fold '=' headers.
function lex:fold(text, start_line, start_level)
	local levels = {}
	local line_num = start_line
	if start_level > FOLD_HEADER then start_level = start_level - FOLD_HEADER end
	for line in (text .. '\n'):gmatch('(.-)\r?\n') do
		local header = line:match('^%s*(=*)')
		-- If the previous line was a header, this line's level has been pre-defined.
		-- Otherwise, use the previous line's level, or if starting to fold, use the start level.
		local level = levels[line_num] or levels[line_num - 1] or start_level
		if level > FOLD_HEADER then level = level - FOLD_HEADER end
		-- If this line is a header, set its level to be one less than the header level
		-- (so it can be a fold point) and mark it as a fold point.
		if #header > 0 then
			level = FOLD_BASE + #header - 1 + FOLD_HEADER
			levels[line_num + 1] = FOLD_BASE + #header
		end
		levels[line_num] = level
		line_num = line_num + 1
	end
	return levels
end

-- Keywords
lex:set_word_list(lexer.KEYWORD, {
	'let', 'set', 'show', 'while', 'for', 'if', 'include', 'import', 'return', 'else', 'in', 'not',
	'and', 'or', 'context'
})

-- Named values
lex:set_word_list(lexer.CONSTANT_BUILTIN, {
	'auto', 'none', 'false', 'true', 'left', 'right', 'top', 'bottom', 'center', 'horizon'
})

-- Unit types
lex:set_word_list('units', {
	'fr', 'pt', 'mm', 'cm', 'in', 'em', 'deg', 'rad', '%'
})

lexer.property['scintillua.comment'] = '//'

return lex
