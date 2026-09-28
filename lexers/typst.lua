-- Copyright 2026 Jamie Drinkell. See LICENSE.
-- Typst LPeg lexer.
-- Reference: https://typst.app/docs/reference/syntax/

local lexer = lexer
local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new(...)

-- Escaped characters (capture them before other rules)
local escapes = S'*_;#<>$'
lex:add_rule('escapes', P'\\' * escapes)

-- Comments
-- Don't try to capture URLs as comments
local line_comment = -B(S'ps' * ':') * lexer.to_eol('//', true)
local block_comment = lexer.range('/*', '*/')
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))

-- Headings
lex:add_rule('header', lex:tag(lexer.HEADING, lexer.to_eol(lexer.starts_line('=', true))))

-- Lists
lex:add_rule('list', lex:tag(lexer.LIST, lexer.starts_line(S('+-'), true) * S(' \t')))

-- Raw Text
local raw_text = lpeg.Cmt(lpeg.C(P('`')^1), function(input, index, bt)
	-- `foo`, ``foo``, ``foo`bar``, `foo``bar` are all allowed.
	local _, e = input:find('[^`]' .. bt .. '%f[^`]', index)
	return (e or #input) + 1
end)
lex:add_rule('raw', lex:tag(lexer.CODE, raw_text))

-- References
local variable = lex:tag(lexer.VARIABLE, lexer.word_utf8 * (S'-.:'^-1 * lexer.word_utf8)^0)
lex:add_rule('reference', lex:tag(lexer.REFERENCE, '@' * variable))

-- Strong and Emphasis
lex:add_rule('strong', lex:tag(lexer.BOLD, lexer.range('*') - (P'* ' + (B(P': ') * P'*\n'))))
lex:add_rule('em', lex:tag(lexer.ITALIC, lexer.range('_') - ((B('let ') * '_') + ('_' * (S' ,')))))

-- Code Expressions
-- Using rules from: https://typst.app/docs/reference/syntax/#code
lex:add_rule('code_mode', lex:tag(lexer.EMBEDDED, P'#' - B('\\') * P'#'))
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, B'#' * lex:word_match(lexer.KEYWORD)))

local operators = S'-+*/=!<>' + P'not' + P'in' + P'and' + P'or'
local func = variable * #S'(['
lex:add_rule('function', lex:tag(lexer.FUNCTION, func))

-- Match some more code mode aspects if they seem like they are situationally in a expression
local ws = lexer.space^1
local assignable = P'"'^-1 * (variable + lexer.number) * P'"'^-1

lex:add_rule('let_bind', lex:tag(lexer.KEYWORD, P'let' * #(ws * ((variable * ws * P'=') + ('(' * variable * ',')))))

lex:add_rule('else_if',
	lex:tag(lexer.KEYWORD, (P'else' * ws * P'if'^-1) - (-B(S']}' * ' ') * P'else')))

lex:add_rule('if', lex:tag(lexer.KEYWORD,
	P'if' * #(ws * ((((assignable + operators^-2) * ws)^0 * S'[{') + func + ('(' * variable * ws* operators)))))

lex:add_rule('set', lex:tag(lexer.KEYWORD, P'set' * #(ws * func)))

lex:add_rule('show', lex:tag(lexer.KEYWORD, P'show' * #(ws * (func + (variable * P': ')))))

lex:add_rule('for', lex:tag(lexer.KEYWORD, P'for' * #(ws *
	((assignable * ws * P'in' * ws * assignable * ws * S'[{') + (lexer.range('(', ')') * ws * P'in')))))

lex:add_rule('in', lex:tag(lexer.KEYWORD, P'in' * #(ws * ((assignable * ws * S'[{') + func))))

lex:add_rule('while',
	lex:tag(lexer.KEYWORD, P'while' * #(ws * ((assignable + operators^2) * ws)^0 * S'[{')))

lex:add_rule('variable', lex:tag(lexer.VARIABLE, B'#' * variable))

lex:add_rule('string', lex:tag(lexer.STRING, lexer.range('"') * #((S'\n:,)') + (ws * S'[{'))))

lex:add_rule('values', lex:tag(lexer.NUMBER, lexer.number * lex:word_match('units')))

-- Lex as a number if after a keyword, assignment or being passed into a function
lex:add_rule('numeric', lex:tag(lexer.NUMBER,
	((B(P'if ') + B(P'while ') + B(P'for ') + B(P'in ')) +
	(B(S'-–+*/=!<>{(,: ' * ' ') + B('(')))
	* lexer.number
	-- Don't match comma delimited numbers, e.g. "4,200+"
	- (lexer.number * ',' * lexer.number)
	))

-- Labels
lex:add_rule('label',
	lex:tag(lexer.LABEL, lexer.range('<', '>', true, false, true) - (P'<=' + P'< ')))

-- Math
lex:add_rule('math', lex:tag(lexer.NUMBER, lexer.range('$')))

-- Links
local link_url = -B(P'"') * 'http' * P('s')^-1 * '://' * (lexer.any - lexer.space)^1 +
	('<' * lexer.alpha^2 * ':' * (lexer.any - lexer.space - '>')^1 * '>')
lex:add_rule('link', lex:tag(lexer.LINK, link_url))

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

-- Keywords that may be immediately after a '#'
lex:set_word_list(lexer.KEYWORD, {
	'let', 'set', 'show', 'while', 'for', 'if', 'include', 'import'
})

-- Unit types
lex:set_word_list('units', {
	'fr', 'pt', 'mm', 'cm', 'in', 'em', 'deg', 'rad', '%'
})

lexer.property['scintillua.comment'] = '//'

return lex
