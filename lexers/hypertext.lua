-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- HTML LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S, V = l.lpeg.P, l.lpeg.R, l.lpeg.S, l.lpeg.V

module(...)

case_insensitive_tags = true

local ws = token('whitespace', l.space^1)

-- comments
local comment = token('comment', '<!--' * (l.any - '-->')^0 * P('-->')^-1)

local doctype = token('doctype', '<!DOCTYPE' * (l.any - '>')^1 * '>')

-- strings
local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local string = token('string', sq_str + dq_str)

local equals = token('operator', '=')
local number = token('number', l.digit^1 * P('%')^-1)

-- tags
local element = token('element', word_match({
  'a', 'abbr', 'acronym', 'address', 'applet', 'area', 'b', 'base', 'basefont',
  'bdo', 'big', 'blockquote', 'body', 'br', 'button', 'caption', 'center',
  'cite', 'code', 'col', 'colgroup', 'dd', 'del', 'dfn', 'dir', 'div', 'dl',
  'dt', 'em', 'fieldset', 'font', 'form', 'frame', 'frameset', 'h1', 'h2', 'h3',
  'h4', 'h5', 'h6', 'head', 'hr', 'html', 'i', 'iframe', 'img', 'input', 'ins',
  'isindex', 'kbd', 'label', 'legend', 'li', 'link', 'map', 'menu', 'meta',
  'noframes', 'noscript', 'object', 'ol', 'optgroup', 'option', 'p', 'param',
  'pre', 'q', 'samp', 'script', 'select', 'small', 'span', 'strike', 'strong',
  'style', 'sub', 'sup', 's', 'table', 'tbody', 'td', 'textarea', 'tfoot', 'th',
  'thead', 'title', 'tr', 'tt', 'u', 'ul', 'var', 'xml'
}, nil, case_insensitive_tags))
local attribute = token('attribute', word_match({
  'abbr', 'accept-charset', 'accept', 'accesskey', 'action', 'align', 'alink',
  'alt', 'archive', 'axis', 'background', 'bgcolor', 'border', 'cellpadding',
  'cellspacing', 'char', 'charoff', 'charset', 'checked', 'cite', 'class',
  'classid', 'clear', 'codebase', 'codetype', 'color', 'cols', 'colspan',
  'compact', 'content', 'coords', 'data', 'datafld', 'dataformatas',
  'datapagesize', 'datasrc', 'datetime', 'declare', 'defer', 'dir', 'disabled',
  'enctype', 'event', 'face', 'for', 'frame', 'frameborder', 'headers',
  'height', 'href', 'hreflang', 'hspace', 'http-equiv', 'id', 'ismap', 'label',
  'lang', 'language', 'leftmargin', 'link', 'longdesc', 'marginwidth',
  'marginheight', 'maxlength', 'media', 'method', 'multiple', 'name', 'nohref',
  'noresize', 'noshade', 'nowrap', 'object', 'onblur', 'onchange', 'onclick',
  'ondblclick', 'onfocus', 'onkeydown', 'onkeypress', 'onkeyup', 'onload',
  'onmousedown', 'onmousemove', 'onmouseover', 'onmouseout', 'onmouseup',
  'onreset', 'onselect', 'onsubmit', 'onunload', 'profile', 'prompt',
  'readonly', 'rel', 'rev', 'rows', 'rowspan', 'rules', 'scheme', 'scope',
  'selected', 'shape', 'size', 'span', 'src', 'standby', 'start', 'style',
  'summary', 'tabindex', 'target', 'text', 'title', 'topmargin', 'type',
  'usemap', 'valign', 'value', 'valuetype', 'version', 'vlink', 'vspace',
  'width', 'text', 'password', 'checkbox', 'radio', 'submit', 'reset', 'file',
  'hidden', 'image', 'xml', 'xmlns', 'xml:lang'
}, '-:', case_insensitive_tags))
local attributes =
  P{ attribute * (ws^0 * equals * ws^0 * (string + number))^-1 * (ws * V(1))^0 }
local tag_start = token('tag', '<' * P('/')^-1) * element
local tag_end = token('tag', P('/')^-1 * '>')
local tag = tag_start * (ws * attributes)^0 * ws^0 * tag_end

-- words
local word = token('default', (l.any - l.space - S('<&'))^1)

-- entities
local entity = token('entity', '&' * (l.any - l.space - ';')^1 * ';')

_rules = {
  { 'whitespace', ws },
  { 'default', word },
  { 'comment', comment },
  { 'doctype', doctype },
  { 'tag', tag },
  { 'entity', entity },
  { 'any_char', l.any_char },
}

_tokenstyles = {
  { 'tag', l.style_tag },
  { 'element', l.style_tag },
  { 'attribute', l.style_nothing..{ bold = true } },
  { 'entity', l.style_nothing..{ bold = true } },
  { 'doctype', l.style_keyword },
}

-- Embedded lexers.

-- Embedded CSS.
local css = l.load('css')

local style_element = word_match({ 'style' }, nil, case_insensitive_tags)
local css_start_rule = #(P('<') * style_element * P(function(input, index)
  if input:find('[^>]+type%s*=%s*(["\'])text/css%1') then return index end
end)) * tag -- <style type="text/css">
local css_end_rule =
  #(P('</') * style_element * ws^0 * P('>')) * tag -- </style>
css._RULES['any_char'] = token('css_default', l.any - css_end_rule)
l.embed_lexer(_M, css, css_start_rule, css_end_rule)
_tokenstyles[#_tokenstyles + 1] = { 'css_default', l.style_nothing }

-- Embedded Javascript.
local js = l.load('javascript')

local script_element = word_match({ 'script' }, nil, case_insensitive_tags)
local js_start_rule = #(P('<') * script_element * P(function(input, index)
  if input:find('[^>]+type%s*=%s*(["\'])text/javascript%1') then
    return index
  end
end)) * tag -- <script type="text/javascript">
local js_end_rule = #('</' * script_element * ws^0 * '>') * tag -- </script>
js._RULES['operator'] =
  token('operator', S('+-/*%^!=&|?:;.()[]{}>') + '<' * -('/' * script_element))
js._RULES['any_char'] = token('js_default', l.any - js_end_rule)
l.embed_lexer(_M, js, js_start_rule, js_end_rule)
_tokenstyles[#_tokenstyles + 1] = { 'js_default', l.style_nothing }

-- Accessible patterns for preprocessing languages (Django, PHP, etc.)
_M.equals = equals
_M.number = number
_M.attribute = attribute
_M.tag_start = tag_start
_M.tag_end = tag_end
