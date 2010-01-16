-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- HTML LPeg lexer

module(..., package.seeall)
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

case_insensitive_tags = true

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', '<!--' * (any - '-->')^0 * P('-->')^-1)

local doctype = token('doctype', '<!DOCTYPE' * (any - '>')^1 * '>')

-- strings
local sq_str = delimited_range("'", '\\', true)
local dq_str = delimited_range('"', '\\', true)
local string = token('string', sq_str + dq_str)

local equals = token('operator', '=')
local number = token('number', digit^1 * P('%')^-1)

-- tags
local element = token('element', word_match(word_list{
  'a', 'abbr', 'acronym', 'address', 'applet', 'area', 'b', 'base',
  'basefont', 'bdo', 'big', 'blockquote', 'body', 'br', 'button',
  'caption', 'center', 'cite', 'code', 'col', 'colgroup', 'dd',
  'del', 'dfn', 'dir', 'div', 'dl', 'dt', 'em', 'fieldset', 'font',
  'form', 'frame', 'frameset', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'head', 'hr', 'html', 'i', 'iframe', 'img', 'input', 'ins',
  'isindex', 'kbd', 'label', 'legend', 'li', 'link', 'map', 'menu',
  'meta', 'noframes', 'noscript', 'object', 'ol', 'optgroup',
  'option', 'p', 'param', 'pre', 'q', 'samp', 'script', 'select',
  'small', 'span', 'strike', 'strong', 'style', 'sub', 'sup',
  's', 'table', 'tbody', 'td', 'textarea', 'tfoot', 'th', 'thead',
  'title', 'tr', 'tt', 'u', 'ul', 'var', 'xml'
}, nil, case_insensitive_tags))
local attribute = token('attribute', word_match(word_list{
  'abbr', 'accept-charset', 'accept', 'accesskey', 'action',
  'align', 'alink', 'alt', 'archive', 'axis', 'background',
  'bgcolor', 'border', 'cellpadding', 'cellspacing', 'char',
  'charoff', 'charset', 'checked', 'cite', 'class', 'classid',
  'clear', 'codebase', 'codetype', 'color', 'cols', 'colspan',
  'compact', 'content', 'coords', 'data', 'datafld',
  'dataformatas', 'datapagesize', 'datasrc', 'datetime', 'declare',
  'defer', 'dir', 'disabled', 'enctype', 'event', 'face', 'for',
  'frame', 'frameborder', 'headers', 'height', 'href', 'hreflang',
  'hspace', 'http-equiv', 'id', 'ismap', 'label', 'lang',
  'language', 'leftmargin', 'link', 'longdesc', 'marginwidth',
  'marginheight', 'maxlength', 'media', 'method', 'multiple',
  'name', 'nohref', 'noresize', 'noshade', 'nowrap', 'object',
  'onblur', 'onchange', 'onclick', 'ondblclick', 'onfocus',
  'onkeydown', 'onkeypress', 'onkeyup', 'onload', 'onmousedown',
  'onmousemove', 'onmouseover', 'onmouseout', 'onmouseup',
  'onreset', 'onselect', 'onsubmit', 'onunload', 'profile',
  'prompt', 'readonly', 'rel', 'rev', 'rows', 'rowspan', 'rules',
  'scheme', 'scope', 'selected', 'shape', 'size', 'span', 'src',
  'standby', 'start', 'style', 'summary', 'tabindex', 'target',
  'text', 'title', 'topmargin', 'type', 'usemap', 'valign',
  'value', 'valuetype', 'version', 'vlink', 'vspace', 'width',
  'text', 'password', 'checkbox', 'radio', 'submit', 'reset',
  'file', 'hidden', 'image', 'xml', 'xmlns', 'xml:lang'
}, '-:', case_insensitive_tags))
local attributes = P{ attribute * (ws^0 * equals * ws^0 * (string + number))^-1 * (ws * V(1))^0 }
local tag_start = token('tag', '<' * P('/')^-1) * element
local tag_end = token('tag', P('/')^-1 * '>')
local tag = tag_start * (ws * attributes)^0 * ws^0 * tag_end

-- words
local word = token('default', (any - space - S('<&'))^1)

-- entities
local entity = token('entity', '&' * (any - space - ';')^1 * ';')

-- embedded languages
local css = require 'css'
local js  = require 'javascript'

function LoadTokens()
  local html = hypertext
  add_token(html, 'whitespace', ws)
  add_token(html, 'default', word)
  add_token(html, 'comment', comment)
  add_token(html, 'doctype', doctype)
  add_token(html, 'tag', tag)
  add_token(html, 'entity', entity)
  add_token(html, 'any_char', any_char)
  css.LoadTokens()
  js.LoadTokens()

  -- embedded languages in HTML
  embed_language(html, css)
  embed_language(html, js)

  -- public access only tokens
  add_token(html, 'attribute', attribute, true)
  add_token(html, 'attributes', attributes, true)
  add_token(html, 'equals', equals, true)
  add_token(html, 'number', number, true)
  add_token(html, 'tag_start', tag_start, true)
  add_token(html, 'tag_end', tag_end, true)
end

function LoadStyles()
  add_style('tag', style_tag)
  add_style('element', style_tag)
  add_style('attribute', style_nothing..{ bold = true })
  add_style('entity', style_nothing..{ bold = true })
  add_style('doctype', style_keyword)
  css.LoadStyles()
  js.LoadStyles()
end
