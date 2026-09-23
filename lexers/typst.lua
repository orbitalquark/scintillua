-- Copyright 2026 Jamie Drinkell. See LICENSE.
-- Typst LPeg lexer.
-- Reference: https://typst.app/docs/reference/syntax/

local lexer = lexer
local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new(...)

-- Typst Code Expression
local ranges =
	lexer.range('{', '}', false, false, true) + lexer.range('(', ')', false, false, true) +
		lexer.word^1 * lexer.space^-1 * lexer.word^-1 * lexer.range('(', ')', false, false, true)

local expression = '#' *
	((lexer.word * lexer.space^-1 * lexer.word^-1 * ranges^-1 * lexer.space^-1 * P('= ') *
		(ranges + lexer.range('"') + lexer.number + lexer.word)) + ranges + lexer.word) * P(';')^-1

lex:add_rule('expression', lex:tag(lexer.EMBEDDED, expression))

-- Headings
lex:add_rule('header', lex:tag(lexer.HEADING, lexer.to_eol(lexer.starts_line('='))))

-- Lists
lex:add_rule('list', lex:tag(lexer.LIST, lexer.starts_line(S('*+-'), true) * S(' \t')))

-- Raw Text
local raw_text = lpeg.Cmt(lpeg.C(P('`')^1), function(input, index, bt)
	-- `foo`, ``foo``, ``foo`bar``, `foo``bar` are all allowed.
	local _, e = input:find('[^`]' .. bt .. '%f[^`]', index)
	return (e or #input) + 1
end)
lex:add_rule('raw', lex:tag(lexer.CODE, raw_text))

-- Links
local link_url = 'http' * P('s')^-1 * '://' * (lexer.any - lexer.space)^1 +
	('<' * lexer.alpha^2 * ':' * (lexer.any - lexer.space - '>')^1 * '>')
lex:add_rule('link', lex:tag(lexer.LINK, link_url))

-- Strong and Emphasis
lex:add_rule('strong', lex:tag(lexer.BOLD, lexer.range('*', true)))
lex:add_rule('em', lex:tag(lexer.ITALIC, lexer.range('_', true)))

-- Math
lex:add_rule('math', lex:tag(lexer.NUMBER, lexer.range('$')))

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

-- Comments
local line_comment = lexer.to_eol('//', true)
local block_comment = lexer.range('/*', '*/')
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))

lexer.property['scintillua.comment'] = '//'

return lex
