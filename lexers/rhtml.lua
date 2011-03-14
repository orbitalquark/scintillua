-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
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
local ruby = l.load('rails')

local ruby_start_rule = token('rhtml_tag', '<%' * P('=')^-1)
local ruby_end_rule = token('rhtml_tag', '%>')
l.embed_lexer(html, ruby, ruby_start_rule, ruby_end_rule, true)

-- TODO: embed in CSS, and JS

_tokenstyles = {
  { 'rhtml_tag', l.style_embedded },
}
