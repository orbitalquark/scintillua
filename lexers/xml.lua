-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- XML LPeg lexer

module(..., package.seeall)
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

local ws = token('whitespace', space^1)

-- comments and CDATA
local comment = token('comment', '<!--' * (any - '-->')^0 * P('-->')^-1)
local cdata = token('cdata', '<![CDATA' * (any - ']]>')^0 * P(']]>')^-1)

-- strings
local sq_str = delimited_range("'", nil, true)
local dq_str = delimited_range('"', nil, true)
local string = token('string', sq_str + dq_str)

local equals = token('operator', '=')
local number = token('number', digit^1 * P('%')^-1)
local alpha = R('az', 'AZ', '\127\255')
local word_char = alnum + S('_-')
local identifier = (alpha + S('_-')) * word_char^0

-- tags
local namespace = token('namespace', identifier)
local element = token('element', identifier) * (token('operator', ':') * namespace)^-1
local normal_attr = token('attribute', identifier)
local xmlns_attr = token('attribute', 'xmlns') * token('operator', ':') * namespace
local attribute = xmlns_attr + normal_attr
local attributes = { attribute * ws^0 * equals * ws^0 * (string + number) * (ws * V(1))^0 }
local tag_start = token('tag', '<' * P('/')^-1) * element
local tag_end = token('tag', P('/')^-1 * '>')
local tag = tag_start * (ws * attributes)^0 * ws^0 * tag_end

-- doctypes
local doctype = token('doctype', '<?xml') * (ws * attributes)^0 * ws^0 * token('doctype', '?>')

-- entities
local entity = token('entity', '&' * word_match(word_list{
  'lt', 'gt', 'amp', 'apos', 'quot'
}) * ';')

function LoadTokens()
  local xml = xml
  add_token(xml, 'whitespace', ws)
  add_token(xml, 'comment', comment)
  add_token(xml, 'cdata', cdata)
  add_token(xml, 'doctype', doctype)
  add_token(xml, 'tag', tag)
  add_token(xml, 'entity', entity)
  add_token(xml, 'any_char', any_char)
end

function LoadStyles()
  add_style('tag', style_tag)
  add_style('element', style_tag)
  add_style('namespace', style_nothing..{ italic = true })
  add_style('attribute', style_nothing..{ bold = true })
  add_style('cdata', style_comment)
  add_style('entity', style_nothing)
  add_style('doctype', style_embedded)
end
