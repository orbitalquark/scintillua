-- Copyright 2025, Didier Willis
-- (Donated to Scintillua, under the same license.)
-- See LICENSE.
--
-- Lexer for the SIL "TeX-like" syntax used by the SILE typesetting system.
--
-- The SILE typesetting system (https://sile-typesetter.org/) can support
-- different input formats, via dedicated "inputters".
-- It is not tied to a given input syntax.
-- Yet, the "SIL in TeX-like flavor" format is a common one, included in the
-- core distribution and used in most of the examples and documentation.
--
-- SIL TeX-like is similar to LaTeX, but with a parity with SIL XML.
-- I.e. \foo[attr=val]{...} is equivalent to <foo attr="val">...</foo>.
-- Environments are syntactic sugar for commands.
-- I.e. \begin[attr=val]{foo}...\end{foo} is the same as \foo[attr=val]{...}.
-- Rules below try to respect this parity.

local lexer = lexer
local P, S, R, Cb, Cg, Ct, Cmt = lpeg.P, lpeg.S, lpeg.R, lpeg.Cb, lpeg.Cg, lpeg.Ct, lpeg.Cmt

local lex = lexer.new(...)
local ws = lex:get_rule('whitespace')

-- 1. Syntax bits.

-- SIL identifiers can contain letters, numbers, and the characters :-.
-- There are additional rules (e.g. no leading digits), but we'll keep it simple here.
local identifier = lexer.alnum^1 * (S(':-') * lexer.alnum^1)^0

-- Reserved hard-coded "pass-through" commands/environments.
local reserved_specials = {
	ftl = 'text', -- Well Fluent has a syntax, but let's not care here.
	lua = 'lua',
	math = 'tex', -- We'd need a (La)TeX math-only lexer to handle this properly.
	raw = 'text',
	script = 'lua',
	-- sil = ... -- It's the default here, so no need to add a rule for it.
	xml = 'xml',
	use = 'lua',
}
-- Other reserved keywords are "comment" and "begin"/"end",
-- but we'll handle them in the rules below.

-- Parameters (key-value pairs).
local eq = lex:tag(lexer.OPERATOR, '=')
local simple_value = (P(1) - S(',;]'))^1
local quoted_value = lexer.range('"', false, false)
local param = lex:tag(lexer.ATTRIBUTE, identifier) * eq * lex:tag(lexer.STRING, quoted_value + simple_value)
local param_list = param * (ws^0 * lex:tag(lexer.OPERATOR, ',') * ws^0 * param)^0
local optparams = (lex:tag(lexer.OPERATOR, '[') * ws^0 * param_list^0 * ws^0 * lex:tag(lexer.OPERATOR, ']'))^0

-- 2. Comments.
local line_comment = lexer.to_eol('%')
local env_comment = lexer.range(P('\\begin') * optparams * P('{comment}'), P('\\end{comment}'))
local cmd_comment = P('\\comment') * optparams * lexer.range('{', '}', false, false, true)
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + env_comment + cmd_comment))

-- 3. Special reserved pass-through commands/environments.

local function check_exit_brace_level(_, _, current_level)
	current_level = tonumber(current_level)
	return current_level == 0
end

local function increment_brace_level(increment)
	local function update_brace_level(_, _, current_level)
		current_level = tonumber(current_level)
		local next_level = tostring(current_level + increment)
		return true, next_level
	end
	return Cg(Cmt(Cb('brace_level'), update_brace_level), 'brace_level')
end

local is_exit_brace = Cmt(Cb('brace_level'), check_exit_brace_level)
local init_brace_level = Cg(Ct('') / '0', 'brace_level')

for name, lang in pairs(reserved_specials) do
	-- Order matters: environments, commands with arguments, commands without arguments.
	-- We need alt names for multiple embeddings and rules.
	local base_rule_id = name .. '_' .. lang

	-- 3.1. Reserved environments.
	-- Ex. \begin{lua} ... Lua code ... \end{lua}
	local env_embedder = lexer.load(lang, base_rule_id .. '_env')
	lex:embed(
		env_embedder,
		lex:tag(lexer.FUNCTION_BUILTIN, '\\begin') * optparams
			* lex:tag(lexer.OPERATOR, '{') * lex:tag(lexer.FUNCTION_BUILTIN, name) * lex:tag(lexer.OPERATOR, '}'),
		lex:tag(lexer.FUNCTION_BUILTIN, '\\end')
			* lex:tag(lexer.OPERATOR, '{') * lex:tag(lexer.FUNCTION_BUILTIN, name) * lex:tag(lexer.OPERATOR, '}'))

	-- 3.2. Reserved commands.
	-- Ex. \lua{... Lua code ...}
	-- The hard trick here is that we want to want to keep track of the paired braces,
	-- in order to exit the embedding on the right closing brace.
	local cmd_embedder = lang == 'text'
		and lexer.new(base_rule_id .. '_cmd') -- pseudo-lexer for text
		or lexer.load(lang, base_rule_id .. '_cmd') -- real lexer for Lua, TeX, XML
	if lang == 'lua' then
		-- We hack the Lua lexer to intercept and handle the pairs of braces,
		-- i.e. we remove them for the 'operator' rule and handle them separately.
		cmd_embedder:modify_rule('operator', cmd_embedder:tag(lexer.OPERATOR, '..' + S('+-*/%^#=<>&|~;:,.[]()')))
		cmd_embedder:add_rule(
			'sil_brace_open',
			cmd_embedder:tag(lexer.OPERATOR, '{') * increment_brace_level(1)
		)
		cmd_embedder:add_rule(
			'sil_brace_close',
			cmd_embedder:tag(lexer.OPERATOR, '}') * increment_brace_level(-1)
		)
	elseif lang == 'tex' then
		-- We hack the TeX math lexer to intercept and handle the pairs of braces,
		-- i.e. we remove them for the 'operator' rule and handle them separately.
		-- We also take the opportunity remove some operators not expected in math mode,
		-- and add some extra operators for math mode.
		cmd_embedder:modify_rule('operator', cmd_embedder:tag(lexer.OPERATOR, S('&()[]')))
		cmd_embedder:add_rule('operator_math', cmd_embedder:tag(lexer.OPERATOR .. ".math", S('+-=^_')))
		cmd_embedder:add_rule(
			'sil_brace_open',
			cmd_embedder:tag(lexer.OPERATOR, '{') * increment_brace_level(1)
		)
		cmd_embedder:add_rule(
			'sil_brace_close',
			cmd_embedder:tag(lexer.OPERATOR, '}') * increment_brace_level(-1)
		)
	else
		-- We just need to keep track of the braces for the XML and text lexers,
		-- without any special marking.
		cmd_embedder:add_rule(
			'sil_brace_open',
			P'{' * increment_brace_level(1)
		)
		cmd_embedder:add_rule(
			'sil_brace_close',
			P'}' * increment_brace_level(-1)
		)
	end
	lex:embed(
		cmd_embedder,
		lex:tag(lexer.FUNCTION_BUILTIN, '\\' .. name) * optparams * init_brace_level * lex:tag(lexer.FUNCTION_BUILTIN, '{'),
		lex:tag(lexer.FUNCTION_BUILTIN, '}' * is_exit_brace)
	)

	-- 3.3. Reserved commands without arguments (must come after the commands with arguments).
	-- Ex. \use[module=packages.highlighter]
	lex:add_rule(base_rule_id .. '_cmd_no_arg', lex:tag(lexer.FUNCTION_BUILTIN, P('\\' .. name)) * optparams)
end

-- 4. Sections (for mere convenience / visibility).
-- As of 0.15.9 SILE's default book class has chapter, section, subsection.
-- The resilient.book class from 3rd-party module resilient.sile adds part,
-- appendix, subsubsection, and frontmatter, mainmatter, backmatter.
local sections = lex:word_match('sections')
lex:set_word_list('sections', {
	'frontmatter', 'mainmatter', 'backmatter',
	'part', 'chapter', 'appendix',
	'section', 'subsection', 'subsubsection',
})
lex:add_rule('section', lex:tag('command.section', '\\' * sections) * optparams)

-- 5. Regular commands/environments.
-- Order matters: environments, commands
local env_cmd = lex:tag(lexer.OPERATOR,'{') * lex:tag(lexer.TAG, identifier) * lex:tag(lexer.OPERATOR, '}')
lex:add_rule(
	'environment_start',
	lex:tag(lexer.FUNCTION_BUILTIN, '\\begin') * optparams * env_cmd
)
lex:add_rule(
	'environment_end',
	lex:tag(lexer.FUNCTION_BUILTIN, '\\end') * env_cmd
)
lex:add_rule('command', lex:tag(lexer.TAG, '\\' * identifier) * optparams)

-- 6. Groups.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('{}')))

lexer.property['scintillua.comment'] = '%'

return lex
