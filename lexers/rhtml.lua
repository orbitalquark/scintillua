-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- RHTML LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

-- Embedded in HTML.

local html = l.load('hypertext')

_lexer = html

-- Embedded lexers.

-- Embedded Ruby.
local ruby = l.load('ruby')

ruby._RULES['whitespace'] = token('rhtml_whitespace', l.space^1)
local ruby_start_rule = token('rhtml_tag', '<%' * P('=')^-1)
local ruby_end_rule = token('rhtml_tag', '%>')
l.embed_lexer(html, ruby, ruby_start_rule, ruby_end_rule, true)

-- TODO: modify HTML, CSS, and JS patterns accordingly

_tokenstyles = {
  { 'rhtml_whitespace', l.style_nothing },
  { 'rhtml_tag', l.style_embedded },
}
