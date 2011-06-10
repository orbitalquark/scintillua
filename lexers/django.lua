-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Django LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S, V = l.lpeg.P, l.lpeg.R, l.lpeg.S, l.lpeg.V

module(...)

local ws = token(l.WHITESPACE, l.space^1)

-- comments
local comment = token(l.COMMENT, '{#' * (l.any - l.newline - '#}')^0 *
                      P('#}')^-1)

-- strings
local string = token(l.STRING, l.delimited_range('"', nil, true))

-- keywords
local keyword = token(l.KEYWORD, word_match {
  'as', 'block', 'blocktrans', 'by', 'endblock', 'endblocktrans', 'comment',
  'endcomment', 'cycle', 'date', 'debug', 'else', 'extends', 'filter',
  'endfilter', 'firstof', 'for', 'endfor', 'if', 'endif', 'ifchanged',
  'endifchanged', 'ifnotequal', 'endifnotequal', 'in', 'load', 'not', 'now',
  'or', 'parsed', 'regroup', 'ssi', 'trans', 'with', 'widthratio'
})

-- functions
local func = token(l.FUNCTION, word_match {
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
local identifier = token(l.IDENTIFIER, l.word)

-- operators
local operator = token(l.OPERATOR, S(':,.|'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'function', func },
  { 'identifier', identifier },
  { 'string', string },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

-- Embedded in HTML.

local html = l.load('hypertext')

_lexer = html

-- Embedded Django.
local django_start_rule = token('django_tag', '{' * S('{%'))
local django_end_rule = token('django_tag', S('%}') * '}')
l.embed_lexer(html, _M, django_start_rule, django_end_rule)

-- Modify HTML patterns to embed Django.
html._RULES['comment'] = html._RULES['comment'] + comment

-- TODO: embed in CSS and JS

_tokenstyles = {
  { 'django_tag', l.style_embedded },
}

local _foldsymbols = html._foldsymbols
_foldsymbols._patterns[#_foldsymbols._patterns + 1] = '{[%%{]'
_foldsymbols._patterns[#_foldsymbols._patterns + 1] = '[%%}]}'
_foldsymbols.django_tag = { ['{{'] = 1, ['{%'] = 1, ['}}'] = -1, ['%}'] = -1 }
