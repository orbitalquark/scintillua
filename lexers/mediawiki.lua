-- Copyright 2006-2025 Mitchell. See LICENSE.
-- MediaWiki LPeg lexer.
-- Contributed by Alexander Misel.
local lexer = lexer
local P, S, B = lpeg.P, lpeg.S, lpeg.B
local lex = lexer.new(...)

-- HTML-like tags
local dq_str = P('"') * ((lexer.any - S('>"\\')) + ('\\' * lexer.any))^0 * P('"')
local unquoted_attr = (lexer.any - (S('"' .. "'" .. '<>=') + lexer.space))^1
local tag_attr = lex:tag(lexer.ATTRIBUTE, lexer.alpha^1 * lexer.space^0 *
	('=' * lexer.space^0 * (dq_str + unquoted_attr))^-1 * lexer.space^0)
local tag_name = lexer.alnum^1
local tag_inner_content = lexer.space^0 * tag_attr^0 * lexer.space^0 * P('/')^-1

-- The tag rule should consume from '<' to the final '>'
lex:add_rule('tag', lex:tag(lexer.TAG, '<' * P('/')^-1 * tag_name * tag_inner_content * P('>')))

-- Internal Link: [[Target]] or [[Target|Display Text]]
-- The content can contain almost anything except unbalanced square brackets.
-- We'll highlight the whole thing as LINK.
local internal_link_content = (lexer.any - P(']]'))^1 -- Matches everything until ']]'
lex:add_rule('internal_link', lex:tag(lexer.LINK, P('[[') * internal_link_content * P(']]')))

-- External Link: [http://example.com Link text] or [http://example.com]
-- Content should start with a protocol (http/s, ftp, mailto etc.)
local protocol = lexer.alpha^2 * P('://')
local external_link_content = (protocol * (lexer.any - P(']'))^1) + (lexer.any - P(']'))^1
lex:add_rule('external_link', lex:tag(lexer.LINK, P('[') * external_link_content * P(']')))

-- Parser Functions: {{#function:args}} or {{function:args}}
-- This is a very complex area. This lexer assumes a simple "name:" pattern.
-- Tag the function name and its arguments.
local parser_function_name = P('#')^-1 * (lexer.alpha + S('_'))^1 * P(':')
local parser_function_content = (lexer.any - S('{}'))^1
lex:add_rule('parser_func',
	lex:tag(lexer.FUNCTION, P('{{') * parser_function_name * parser_function_content * P('}}')))

-- Templates and Variables: {{TemplateName|args}} or {{VARIABLENAME}}
-- Tag the template/variable name.
-- This rule needs to be placed *after* parser_func if there's any ambiguity in parsing.
local template_or_variable_name = (lexer.alnum + S('_'))^1
local template_content = (P('|') * (lexer.any - S('{}'))^1)^-1 -- Optional content after |
lex:add_rule('template',
	lex:tag(lexer.VARIABLE, P('{{') * template_or_variable_name * template_content * P('}}')))

-- Headings (e.g., == My Heading ==)
-- Capture the heading text as lexer.HEADING
local heading_level = S('=')^1
lex:add_rule('heading',
	lex:tag(lexer.HEADING, lexer.starts_line(heading_level * lexer.space^0 *
		(lexer.any - S('=') - lexer.newline)^1 * lexer.space^0 * heading_level)))

-- Operators.
-- Consider adding more specific rules for bold/italic instead of general operators.
-- For now, keep existing general operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('-=|#~!')))

-- Behavior switches (e.g., __TOC__)
lex:add_rule('behavior_switch',
    lex:tag(lexer.KEYWORD, lex:word_match('behavior_switch')))

-- Comments.
lex:add_rule('comment', lex:tag(lexer.COMMENT, lexer.range('<!--', '-->')))

-- Word lists
lex:set_word_list('behavior_switch',
	{'__TOC__', '__FORCETOC__', '__NOTOC__', '__NOEDITSECTION__', '__NOCC__',
	'__NOINDEX__', '__NOKEYWORDLINK__', '__NOCONTENTCONVERT__', '__NOEDITSECTION__'})

lexer.property['scintillua.comment'] = '<!--|-->'
lexer.property['scintillua.angle.braces'] = '1'

return lex
