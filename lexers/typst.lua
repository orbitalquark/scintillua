-- Copyright 2026 Jamie Drinkell. See LICENSE.
-- Typst LPeg lexer.
-- Reference: https://typst.app/docs/reference/syntax/

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Escaped characters (capture them before other rules)
lex:add_rule('escapes', P('\\*') + P('\\_') + P('\\;') + P('\\#') + P('\\<') + P('\\>'))

-- Comments
local line_comment = lexer.to_eol('//', true)
local block_comment = lexer.range('/*', '*/')
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))

-- Headings
lex:add_rule('header', lex:tag(lexer.HEADING, lexer.to_eol(lexer.starts_line('='))))

-- Lists
lex:add_rule('list', lex:tag(lexer.LIST, lexer.starts_line(S('+-'), true) * S(' \t')))

-- Raw Text
local raw_text = lpeg.Cmt(lpeg.C(P('`')^1), function(input, index, bt)
	-- `foo`, ``foo``, ``foo`bar``, `foo``bar` are all allowed.
	local _, e = input:find('[^`]' .. bt .. '%f[^`]', index)
	return (e or #input) + 1
end)
lex:add_rule('raw', lex:tag(lexer.CODE, raw_text))

-- Labels
lex:add_rule('label', lex:tag(lexer.LABEL, lexer.range('<', '>', false, false, true)))

-- References
lex:add_rule('reference', lex:tag(lexer.REFERENCE, '@' * (lexer.word_utf8 * (P'-'^-1 * lexer.word_utf8)^0) ))

-- Strong and Emphasis
lex:add_rule('strong', lex:tag(lexer.BOLD, lexer.range('*', true)))
lex:add_rule('em', lex:tag(lexer.ITALIC, lexer.range('_', true)))

-- Code Expressions
-- Using rules from: https://typst.app/docs/reference/syntax/#code
local operators = S'-+*/=!<>'^-2 + P'not' + P'in' + P'and' + P'or'
local varwithdot = lexer.word * P('.')^-1 * lexer.word^-1
local string_type = lexer.range('"')
local code_block = lexer.range('{', '}', false, false, true)
local parenthesized = lexer.range('(', ')', false, false, true)
local content = lexer.range('[', ']', false, false, true)
local code_content = code_block + content
local func = varwithdot * parenthesized * content^-1
local assignables = string_type + func + lexer.number + parenthesized + varwithdot + code_content
local assignment = varwithdot * P' = ' * assignables * (P' ' * (operators * ' ' * assignables))^0
local let_bind = P'let ' * varwithdot * P' = ' *
	(parenthesized + assignables * (P' ' * (operators * ' ' * assignables))^0)
local named_func = P'let ' * func * P' = ' * (parenthesized + code_block + lexer.to_eol())
local conditional_if = P'if ' * assignables * (P' ' * (operators * ' ' * assignables))^0 * ' ' *
	code_content
local conditional = conditional_if * (P' else ' * conditional_if * (P' else '^-1) + code_content)^0
local for_loop = P'for ' * varwithdot * P' in ' * assignables * ' ' * code_content
local while_loop = P'while ' * varwithdot * ' ' * operators * ' ' * assignables * ' ' * code_content
local set_rule = P'set ' * func
local set_if = set_rule * conditional
local show = P'show' * (': ' + (' ' * varwithdot)) * S': '^-2 * (func + set_rule + varwithdot)
local include = P'include ' * string_type
local import = P'import ' * string_type * ((P': ' + P' as ') * lexer.to_eol())^-1

local expression = '#' *
	(code_block + parenthesized + content + func + let_bind + named_func + set_if + set_rule +
		for_loop + while_loop + conditional + assignment + include + import + show + varwithdot) *
	P';'^-1

lex:add_rule('expression', lex:tag(lexer.EMBEDDED, expression))

-- Math
lex:add_rule('math', lex:tag(lexer.NUMBER, lexer.range('$')))

-- Links
local link_url = 'http' * P('s')^-1 * '://' * (lexer.any - lexer.space)^1 +
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

lexer.property['scintillua.comment'] = '//'

return lex
