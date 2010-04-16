-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- ASP LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

-- Embedded in HTML.

local html = l.load('hypertext')

_lexer = html

-- Embedded lexers.

-- Embedded VB
local vb = l.load('vb')

vb._RULES['whitespace'] = token('vb_whitespace', l.space^1)
local vb_start_rule = token('asp_tag', '<%' * P('=')^-1)
local vb_end_rule = token('asp_tag', '%>')
--vb._RULES['string'] = -P('%>') * vb._RULES['string']
vb._RULES['any_char'] = token('vb_default', l.any - vb_end_rule)
l.embed_lexer(html, vb, vb_start_rule, vb_end_rule, true)

-- TODO: modify HTML, CSS, and JS patterns accordingly

-- Embedded VBScript
local vbs = l.load('vbscript')

vbs._RULES['whitespace'] = token('vbscript_whitespace', l.space^1)
local script_element = word_match({ 'script' }, nil, html.case_insensitive_tags)
local vbs_start_rule = #(P('<') * script_element *
  P(function(input, index)
    if input:find('[^>]+language%s*=%s*(["\'])vbscript%1') then return index end
  end)) * html._RULES['tag'] -- <script language="vbscript">
local vbs_end_rule = #('</' * script_element * l.space^0 * '>') * html._RULES['tag'] -- </script>
vbs._RULES['operator'] = token('operator', S('=>+-*^&:.,_()')) + '<' * -('/' * script_element)
vbs._RULES['any_char'] = token('vb_default', l.any - vbs_end_rule)
l.embed_lexer(html, vbs, vbs_start_rule, vbs_end_rule)

_tokenstyles = {
  { 'asp_tag', l.style_embedded },
  { 'vb_whitespace', l.style_nothing },
  { 'vb_default', l.style_nothing },
  { 'vbscript_whitespace', l.style_nothing },
  { 'vbscript_default', l.style_nothing },
}
