local lexer = lexer
local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new(...)

-- This lexer embeds itself with an alternate name. Detect if this instance is the parent or
-- child because some rules differ between parent and child.
local scripting = ... == 'typst_scripting'

if not scripting then
	-- Keep things simple for now and only allow bold and italic in non-code mode
	local italic = -B('\\') * lex:tag(lexer.ITALIC, lexer.range('_', '_'))
	local bold = -B('\\') * lex:tag(lexer.BOLD, lexer.range('*', '*'))

	lex:add_rule('bold', bold)
	lex:add_rule('italic', italic)
end

local function header(level)
	local hspace = (lexer.space - '\n')
	local equals_signs = P('=')^level
	-- Stupid header rule for now
	local header = (lexer.starts_line(hspace^0 * equals_signs * hspace^1) * (lexer.any - S('\n'))^0)
	--[[
  local header = (lexer.starts_line(hspace^0 * equals_signs * hspace^1) * (lexer.any - S('#@<\n'))^0) +
				(((B('[') * hspace^0 * equals_signs * hspace^1)) *
				(lexer.any - S('#@<'))^0)
]]
	return lex:tag(string.format('%s.h%s', lexer.HEADING, level), header)
end

local function build_rules(pre)
	local hash_word = -B('\\') * pre * lexer.word
	local keyword_match = -B('\\') * pre * lex:word_match(lexer.KEYWORD)

	return {
		in_code = -B('\\') * lexer.range('`', false, false),
		dq_string = -B('\\') * lexer.range('"', true),
		string = -B('\\') * lexer.range('`', false, false) + -B('\\') * lexer.range('"', true),

		hash_word = hash_word, keyword_match = keyword_match,

--    TODO: limit numeric values to only be tagged when used as args, assigned values
		--    numeric_value = (lexer.number^1 * ('.' * lexer.number^1)^-1 * lex:word_match('UNITS')^-1),
		iden = lex:tag(lexer.IDENTIFIER, hash_word),
		mod_func = lex:tag(lexer.KEYWORD, hash_word) * lexer.space^1 *
			lex:tag(lexer.FUNCTION, lexer.word) * lex:tag(lexer.OPERATOR, S('[(')),
		func = lex:tag(lexer.FUNCTION, hash_word) * lex:tag(lexer.OPERATOR, S('[(')),
		method = lex:tag(lexer.IDENTIFIER, hash_word) * lex:tag(lexer.OPERATOR, P('.')) *
			lex:tag(lexer.FUNCTION_METHOD, lexer.word) * lex:tag(lexer.OPERATOR, S('[(')),
		field = lex:tag(lexer.IDENTIFIER, hash_word) * lex:tag(lexer.OPERATOR, P('.')) *
			lex:tag('FIELD', lexer.word) * -S('[('),
		operator = lex:tag(lexer.OPERATOR, S('+-/*%<>~!=^&|?~:;,.()[]{}')),
		label = -B('\\') * lex:tag(lexer.LABEL, P('<') * lexer.word * P('>')),
		label_two = -B('\\') * lex:tag(lexer.LABEL, P('@') * lexer.word),
		link = P('http') * P('s')^-1 * P(':') * (lexer.word + S('.:/'))^1,

		math = -B('\\') * lexer.range('$', false, false), code = lexer.range('```', '```', false),
		list = lex:tag(lexer.LIST, lexer.starts_line(lexer.digit^1 * '.' + S('+-'), true) * S(' \t')),
		-- TODO: Do we really need to not tag a number if procceded by an alpha
		comment = lex:tag(lexer.COMMENT, lexer.range('/*', '*/') + lexer.to_eol('//')),

		keyword = lex:tag(lexer.KEYWORD, keyword_match),

		header = header(6) + header(5) + header(4) + header(3) + header(2) + header(1)
	}
end

-- Keywords, functions... don't need '#' when in code
-- the character `#` is not valid in code
-- TODO: only enable styling and text related rules when in []
local rules = build_rules(not scripting and '#' or '')
lex:add_rule('header', rules.header)
lex:add_rule('field', rules.field)
lex:add_rule('function', rules.mod_func + rules.func)
lex:add_rule('method', rules.method)
lex:add_rule('label', rules.label + rules.label_two)
lex:add_rule('code', lex:tag(lexer.CODE, rules.code))
lex:add_rule('string', lex:tag(lexer.STRING, rules.string))
lex:add_rule('link', lex:tag(lexer.LINK, rules.link))
lex:add_rule('math', lex:tag('environment.math', rules.math))
lex:add_rule('keyword', rules.keyword)
lex:add_rule('identifier', rules.iden)
-- lex:add_rule('number', lex:tag(lexer.NUMBER, rules.numeric_value))
lex:add_rule('list', rules.list)
lex:add_rule('comment', rules.comment)
lex:add_rule('operator', rules.operator)

if not scripting then
	local self = lexer.load('typst', 'typst_scripting')

	--[[
	 #{ ... }
		 OR
	 #let x = { ... }
	]]
	-- This is very limited, since it would only work correctly if no nested structures (w/ brackets) are found inside
	-- otherwise (if they're found inside), the first closing bracket of that nested structure would close the whole embedded
	-- script, causing the rest of the script to not be treated as a part of embedded script
	local start = (lex:tag(lexer.KEYWORD, P('#') * lex:word_match(lexer.KEYWORD)) *
		#((lexer.any - S('{;\n'))^1 * S('{') * lexer.space^0)) +
		lex:tag(lexer.OPERATOR, P('#') * S('{'))
	local embed_start = lex:tag(lexer.EMBEDDED, start)
	local embed_end = lexer:tag(lexer.EMBEDDED, S('}'))
	lex:embed(self, embed_start, embed_end)
end

lex:set_word_list(lexer.KEYWORD, {
	'if', 'else', 'for', 'while', 'let', 'set', 'import', 'include', 'return', 'true', 'false',
	'none', 'auto', 'not', 'in', 'and', 'or', 'as', 'show'
})

lex:set_word_list('UNITS', {'em', 'in', '%', 'mm', 'deg', 'rad', 'cm', 'pt', 'fr'})

lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.PREPROCESSOR, '```', '```')
lexer.property['scintillua.comment'] = '//'

return lex

