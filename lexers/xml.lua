-- Copyright 2006-2011 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- XML LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S, V = l.lpeg.P, l.lpeg.R, l.lpeg.S, l.lpeg.V

module(...)

local ws = token(l.WHITESPACE, l.space^1)

-- comments and CDATA
local comment = token(l.COMMENT, '<!--' * (l.any - '-->')^0 * P('-->')^-1)
local cdata = token('cdata', '<![CDATA[' * (l.any - ']]>')^0 * P(']]>')^-1)

-- strings
local sq_str = l.delimited_range("'", nil, true)
local dq_str = l.delimited_range('"', nil, true)
local string = token(l.STRING, sq_str + dq_str)

local equals = token(l.OPERATOR, '=')
local number = token(l.NUMBER, l.digit^1 * P('%')^-1)
local alpha = R('az', 'AZ', '\127\255')
local word_char = l.alnum + S('_-:.??')
local identifier = (l.alpha + S('_-:.??')) * word_char^0

-- tags
local namespace = token('namespace', identifier)
local element = token('element', identifier) *
                (token(l.OPERATOR, ':') * namespace)^-1
local normal_attr = token('attribute', identifier)
local xmlns_attr = token('attribute', identifier) * token(l.OPERATOR, ':') *
                   namespace
local attribute = xmlns_attr + normal_attr
local attributes = { attribute * ws^0 * equals * ws^0 * (string + number) *
                     (ws * V(1))^0 }
local tag_start = token('tag', '<' * P('/')^-1) * element
local tag_end = token('tag', P('/')^-1 * '>')
local tag = tag_start * (ws * attributes)^0 * ws^0 * tag_end

-- doctypes
local doctype = token('doctype', '<?xml') * (ws * attributes)^0 * ws^0 *
                token('doctype', '?>')

-- entities
local entity = token('entity', '&' * word_match {
  'lt', 'gt', 'amp', 'apos', 'quot'
} * ';')

_rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'cdata', cdata },
  { 'doctype', doctype },
  { 'tag', tag },
  { 'entity', entity },
  { 'any_char', l.any_char },
}

_tokenstyles = {
  { 'tag', l.style_tag },
  { 'element', l.style_tag },
  { 'namespace', l.style_nothing..{ italic = true } },
  { 'attribute', l.style_nothing..{ bold = true } },
  { 'cdata', l.style_comment },
  { 'entity', l.style_nothing },
  { 'doctype', l.style_embedded },
}

_foldsymbols = {
  _patterns = { '</?', '<!%-%-', '%-%->', '<!%[CDATA%[', '%]%]>' },
  comment = { ['<!--'] = 1, ['-->'] = -1 },
  cdata = { ['<![CDATA['] = 1, [']]>'] = -1 },
  tag = { ['<'] = 1, ['</'] = -1 }
}
