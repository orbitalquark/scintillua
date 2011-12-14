-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- JSP LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

module(...)

-- Embedded in HTML.
local html = l.load('hypertext')
_lexer = html

-- Embedded Java.
local java = l.load('java')
local java_start_rule = token('jsp_tag', '<%' * P('=')^-1)
local java_end_rule = token('jsp_tag', '%>')
l.embed_lexer(html, java, java_start_rule, java_end_rule, true)

_tokenstyles = {
  { 'jsp_tag', l.style_embedded },
}

local _foldsymbols = html._foldsymbols
_foldsymbols._patterns[#_foldsymbols._patterns + 1] = '<%%'
_foldsymbols._patterns[#_foldsymbols._patterns + 1] = '%%>'
_foldsymbols.jsp_tag = { ['<%'] = 1, ['%>'] = -1 }
