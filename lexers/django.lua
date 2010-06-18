-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Django LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S, V = l.lpeg.P, l.lpeg.R, l.lpeg.S, l.lpeg.V

module(...)

local ws = token('django_whitespace', l.space^1)

-- comments
local comment =
  token('comment', '{#' * (l.any - l.newline - '#}')^0 * P('#}')^-1)

-- strings
local string = token('string', l.delimited_range('"', nil, true))

-- keywords
local keyword = token('keyword', word_match {
  'as', 'block', 'blocktrans', 'by', 'endblock', 'endblocktrans', 'comment',
  'endcomment', 'cycle', 'date', 'debug', 'else', 'extends', 'filter',
  'endfilter', 'firstof', 'for', 'endfor', 'if', 'endif', 'ifchanged',
  'endifchanged', 'ifnotequal', 'endifnotequal', 'in', 'load', 'not', 'now',
  'or', 'parsed', 'regroup', 'ssi', 'trans', 'with', 'widthratio'
})

-- functions
local func = token('function', word_match {
  'add', 'addslashes', 'capfirst', 'center', 'cut', 'date', 'default',
  'dictsort', 'dictsortreversed', 'divisibleby', 'escape', 'filesizeformat',
  'first', 'fix_ampersands', 'floatformat', 'get_digit', 'join', 'length',
  'length_is', 'linebreaks', 'linebreaksbr', 'linenumbers', 'ljust', 'lower',
  'make_list', 'phone2numeric', 'pluralize', 'pprint', 'random', 'removetags',
  'rjust', 'slice', 'slugify', 'stringformat', 'striptags', 'time', 'timesince',
  'title', 'truncatewords', 'unordered_list', 'upper', 'urlencode', 'urlize',
  'urlizetrunc', 'wordcount', 'wordwrap', 'yesno',
})

-- identifiers
local identifier = token('identifier', l.word)

-- operators
local operator = token('operator', S(':,.|'))

_rules = {
  { 'django_whitespace', ws },
  { 'keyword', keyword },
  { 'function', func },
  { 'identifier', identifier },
  { 'string', string },
  { 'operator', operator },
  { 'any_char', token('django_default', l.any - S('%}') * '}') },
}

-- Embedded in HTML.

local html = l.load('hypertext')

_lexer = html

-- Embedded Django.
local django_start_rule = token('django_tag', '{' * S('{%'))
local django_end_rule = token('django_tag', S('%}') * '}')
l.embed_lexer(html, _M, django_start_rule, django_end_rule, true)

-- Modify HTML patterns to embed Django.
local django_rules = _M._EMBEDDEDRULES[html._NAME]
local django_rule =
  django_rules.start_rule * django_rules.token_rule^0 * django_rules.end_rule^-1
html._RULES['comment'] = html._RULES['comment'] + comment
local embedded_sq_str =
  l.delimited_range_with_embedded("'", '\\', 'string', django_rule)
local embedded_dq_str =
  l.delimited_range_with_embedded('"', '\\', 'string', django_rule)
html._RULES['string'] = embedded_sq_str + embedded_dq_str
local attributes = P{
  html.attribute * (ws^0 * html.equals * ws^0 *
    (django_rule + string + html.number))^-1 * (ws * V(1))^0
}
html._RULES['tag'] =
  html.tag_start * (ws^0 * (attributes + django_rule))^0 * ws^0 * html.tag_end

-- TODO: modify CSS and JS patterns accordingly

_tokenstyles = {
  { 'django_whitespace', l.style_nothing },
  { 'django_default', l.style_nothing },
  { 'django_tag', l.style_embedded },
}
