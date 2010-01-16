-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Django LPeg lexer

module(..., package.seeall)
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

local ws = token('django_whitespace', space^1)

-- comments
local comment = token('comment', '{#' * (any - newline - '#}')^0 * P('#}')^-1)

-- strings
local string = token('string', delimited_range('"', nil, true))

-- keywords
local keyword = token('keyword', word_match(word_list{
  'as', 'block', 'blocktrans', 'by', 'endblock', 'endblocktrans', 'comment',
  'endcomment', 'cycle', 'date', 'debug', 'else', 'extends', 'filter',
  'endfilter', 'firstof', 'for', 'endfor', 'if', 'endif', 'ifchanged',
  'endifchanged', 'ifnotequal', 'endifnotequal', 'in', 'load', 'not', 'now',
  'or', 'parsed', 'regroup', 'ssi', 'trans', 'with', 'widthratio'
}))

-- functions
local func = token('function', word_match(word_list{
  'add', 'addslashes', 'capfirst', 'center', 'cut', 'date', 'default',
  'dictsort', 'dictsortreversed', 'divisibleby', 'escape', 'filesizeformat',
  'first', 'fix_ampersands', 'floatformat', 'get_digit', 'join', 'length',
  'length_is', 'linebreaks', 'linebreaksbr', 'linenumbers', 'ljust', 'lower',
  'make_list', 'phone2numeric', 'pluralize', 'pprint', 'random', 'removetags',
  'rjust', 'slice', 'slugify', 'stringformat', 'striptags', 'time', 'timesince',
  'title', 'truncatewords', 'unordered_list', 'upper', 'urlencode', 'urlize',
  'urlizetrunc', 'wordcount', 'wordwrap', 'yesno',
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S(':,.|'))

local html = require 'hypertext'

function LoadTokens()
  html.LoadTokens()
  local django = django
  add_token(django, 'django_whitespace', ws)
  add_token(django, 'keyword', keyword)
  add_token(django, 'function', func)
  add_token(django, 'identifier', identifier)
  add_token(django, 'string', string)
  add_token(django, 'operator', operator)
  add_token(django, 'any_char', token('django_default', any - S('%}') * '}'))

  -- embedding Django in HTML
  local start_token = token('django_tag', '{' * S('{%'))
  local end_token = token('django_tag', S('%}') * '}')
  make_embeddable(django, html, start_token, end_token)
  embed_language(html, django, true)

  -- modify various HTML patterns to accomodate PHP embedding
  local edjango = start_token * django.Token^0 * end_token^-1
  -- comments
  html.TokenPatterns.comment = html.TokenPatterns.comment + comment
  -- strings
  local sq_str = delimited_range_with_embedded("'", '\\', 'string', edjango)
  local dq_str = delimited_range_with_embedded('"', '\\', 'string', edjango)
  local string = sq_str + dq_str
  html.TokenPatterns.string = string
  -- tags
  local ht = html.TokenPatterns
  local attributes = P{ ht.attribute * (ws^0 * ht.equals * ws^0 * (edjango + string + ht.number))^-1 * (ws * V(1))^0 }
  local tag = ht.tag_start * (ws^0 * (attributes + edjango))^0 * ws^0 * ht.tag_end
  html.TokenPatterns.tag = tag
  rebuild_token(html)
  rebuild_tokens(html)

  -- TODO: modify CSS and JS patterns accordingly

  UseOtherTokens = html.Tokens
end

function LoadStyles()
  html.LoadStyles()
  add_style('django_whitespace', style_nothing)
  add_style('django_default', style_nothing)
  add_style('django_tag', style_embedded)
end
