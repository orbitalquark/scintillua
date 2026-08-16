-- Copyright 2006-2026 Mitchell. See LICENSE.
-- MediaWiki LPeg lexer.
-- Contributed by Alexander Misel.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Comments (high priority to avoid conflicts)
lex:add_rule('comment', lex:tag(lexer.COMMENT, lexer.range('<!--', '-->')))

-- HTML-like tags
local tag_start = lex:tag(lexer.TAG, '<' * P('/')^-1 * lexer.alnum^1 * lexer.space^0)
local tag_end = lex:tag(lexer.TAG, P('/')^-1 * '>')
local unquoted_attr = (lexer.any - (S('"' .. "'" .. '<>=') + lexer.space))^1
local tag_attr = lex:tag(lexer.ATTRIBUTE, lexer.alpha^1 * lexer.space^0 *
	('=' * lexer.space^0 * (lexer.range('"') + unquoted_attr))^-1 * lexer.space^0)
lex:add_rule('tag', tag_start * tag_attr^0 * tag_end)

-- Internal Links
lex:add_rule('internal_link', lex:tag(lexer.LINK, lexer.range('[[', ']]')))

-- External Links
lex:add_rule('external_link', lex:tag(lexer.LINK,
	P('[') * lex:word_match(lexer.TYPE) * P('://') *
	(lexer.any - P(']'))^0 * P(']')))

-- Parser Functions
lex:add_rule('parser_func', lex:tag(lexer.FUNCTION,
	P('{{') * P('#')^-1 * lexer.alpha^1 * P(':') *
	(lexer.any - S('{}'))^0 * P('}}')))

-- Templates and Variables
lex:add_rule('template', lex:tag(lexer.VARIABLE,
	P('{{') * lexer.alpha^1 * (P('|') * (lexer.any - S('{}'))^0)^0 * P('}}')))

-- Headings
lex:add_rule('heading', lex:tag(lexer.HEADING,
	lexer.starts_line(S('=')^2 * lexer.space^0 *
	(lexer.any - S('=\r\n'))^1 * lexer.space^0 * S('=')^2)))

-- Bold and Italic formatting
lex:add_rule('bold', lex:tag(lexer.BOLD, lexer.range("'''", "'''")))
lex:add_rule('italic', lex:tag(lexer.ITALIC, lexer.range("''", "''")))

-- Behavior switches
lex:add_rule('behavior_switch',
	lex:tag(lexer.PREPROCESSOR, lex:word_match(lexer.PREPROCESSOR)))

-- Word lists
lex:set_word_list(lexer.TYPE, {
	'http', 'https', 'ftp', 'ftps', 'mailto', 'news', 'irc', 'gopher'
})

lex:set_word_list(lexer.PREPROCESSOR, {
	'__NOTOC__', '__FORCETOC__', '__TOC__', '__NOEDITSECTION__', '__NEWSECTIONLINK__',
	'__NONEWSECTIONLINK__', '__NOGALLERY__', '__HIDDENCAT__', '__NOCONTENTCONVERT__',
	'__NOCC__', '__NOTITLECONVERT__', '__NOTC__', '__START__', '__END__', '__INDEX__',
	'__NOINDEX__', '__STATICREDIRECT__', '__DISAMBIG__'
})

--- Properties
lexer.property['scintillua.comment'] = '<!--|-->'
lexer.property['scintillua.angle.braces'] = '1'

return lex
