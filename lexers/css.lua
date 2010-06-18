-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- CSS LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S, V = l.lpeg.P, l.lpeg.R, l.lpeg.S, l.lpeg.V

module(...)

local ws = token('css_whitespace', l.space^1)

-- comments
local comment = token('comment', '/*' * (l.any - '*/')^0 * P('*/')^-1)

local word_char = l.alnum + S('_-')
local identifier = l.alpha^1 * word_char^0

-- at rules
local at_rule = word_match {
  'import', 'media', 'page', 'font-face', 'charset'
}
local at_rule_arg = word_match {
  'all', 'aural', 'braille', 'embossed', 'handheld', 'print',
  'projection', 'screen', 'tty', 'tv'
}
local at_rule = token('at_rule', '@' * at_rule * (l.space * at_rule_arg)^-1)

-- strings
local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local string = token('string', sq_str + dq_str)

local colon = token('operator', ':')
local semicolon = token('operator', ';')
local comma = token('operator', ',')
local obrace = token('operator', '{')
local cbrace = token('operator', '}')

-- selectors
local attribute =
  '[' * word_char^1 * (S('|~')^-1 * '=' * (identifier + sq_str + dq_str))^-1 *
  ']'
local class_id_selector = identifier^-1 * S('.#') * identifier
local selector =
  '*' * l.space + (class_id_selector + identifier + '*') * attribute^-1
local pseudoclass = word_match {
  'first-letter', 'first-line', 'link', 'active', 'visited',
  'first-child', 'focus', 'hover', 'lang', 'before', 'after',
  'left', 'right', 'first'
}
selector =
  token('css_selector', selector * (l.space * selector)^0) *
        (token('css_selector', ':' * pseudoclass) +
         token('default', ':' * word_char^1))^-1
selector =
  selector * (ws^0 * (comma + token('css_selector', S('>+*'))) * ws^0 *
    selector)^0

-- css properties and values
local css1_property = word_match({
  'color', 'background-color', 'background-image', 'background-repeat',
  'background-attachment', 'background-position', 'background', 'font-family',
  'font-style', 'font-variant', 'font-weight', 'font-size', 'font',
  'word-spacing', 'letter-spacing', 'text-decoration', 'vertical-align',
  'text-transform', 'text-align', 'text-indent', 'line-height', 'margin-top',
  'margin-right', 'margin-bottom', 'margin-left', 'margin', 'padding-top',
  'padding-right', 'padding-bottom', 'padding-left', 'padding',
  'border-top-width', 'border-right-width', 'border-bottom-width',
  'border-left-width', 'border-width', 'border-top', 'border-right',
  'border-bottom', 'border-left', 'border', 'border-color', 'border-style',
  'width', 'height', 'float', 'clear', 'display', 'white-space',
  'list-style-type', 'list-style-image', 'list-style-position', 'list-style'
}, '-')
local css1_value = word_match({
  'auto', 'none', 'normal', 'italic', 'oblique', 'small-caps', 'bold', 'bolder',
  'lighter', 'xx-small', 'x-small', 'small', 'medium', 'large', 'x-large',
  'xx-large', 'larger', 'smaller', 'transparent', 'repeat', 'repeat-x',
  'repeat-y', 'no-repeat', 'scroll', 'fixed', 'top', 'bottom', 'left', 'center',
  'right', 'justify', 'both', 'underline', 'overline', 'line-through', 'blink',
  'baseline', 'sub', 'super', 'text-top', 'middle', 'text-bottom', 'capitalize',
  'uppercase', 'lowercase', 'thin', 'medium', 'thick', 'dotted', 'dashed',
  'solid', 'double', 'groove', 'ridge', 'inset', 'outset', 'block', 'inline',
  'list-item', 'pre', 'no-wrap', 'inside', 'outside', 'disc', 'circle',
  'square', 'decimal', 'lower-roman', 'upper-roman', 'lower-alpha',
  'upper-alpha', 'aqua', 'black', 'blue', 'fuchsia', 'gray', 'green', 'lime',
  'maroon', 'navy', 'olive', 'purple', 'red', 'silver', 'teal', 'white',
  'yellow'
}, '-')
local css2_property = word_match({
  'border-top-color', 'border-right-color', 'border-bottom-color',
  'border-left-color', 'border-color', 'border-top-style', 'border-right-style',
  'border-bottom-style', 'border-left-style', 'border-style', 'top', 'right',
  'bottom', 'left', 'position', 'z-index', 'direction', 'unicode-bidi',
  'min-width', 'max-width', 'min-height', 'max-height', 'overflow', 'clip',
  'visibility', 'content', 'quotes', 'counter-reset', 'counter-increment',
  'marker-offset', 'size', 'marks', 'page-break-before', 'page-break-after',
  'page-break-inside', 'page', 'orphans', 'widows', 'font-stretch',
  'font-size-adjust', 'unicode-range', 'units-per-em', 'src', 'panose-1',
  'stemv', 'stemh', 'slope', 'cap-height', 'x-height', 'ascent', 'descent',
  'widths', 'bbox', 'definition-src', 'baseline', 'centerline', 'mathline',
  'topline', 'text-shadow', 'caption-side', 'table-layout', 'border-collapse',
  'border-spacing', 'empty-cells', 'speak-header', 'cursor', 'outline',
  'outline-width', 'outline-style', 'outline-color', 'volume', 'speak',
  'pause-before', 'pause-after', 'pause', 'cue-before', 'cue-after', 'cue',
  'play-during', 'azimuth', 'elevation', 'speech-rate', 'voice-family', 'pitch',
  'pitch-range', 'stress', 'richness', 'speak-punctuation', 'speak-numeral'
}, '-')
local css2_value = word_match({
  'inherit', 'run-in', 'compact', 'marker', 'table', 'inline-table',
  'table-row-group', 'table-header-group', 'table-footer-group', 'table-row',
  'table-column-group', 'table-column', 'table-cell', 'table-caption', 'static',
  'relative', 'absolute', 'fixed', 'ltr', 'rtl', 'embed', 'bidi-override',
  'visible', 'hidden', 'scroll', 'collapse', 'open-quote', 'close-quote',
  'no-open-quote', 'no-close-quote', 'decimal-leading-zero', 'lower-greek',
  'lower-latin', 'upper-latin', 'hebrew', 'armenian', 'georgian',
  'cjk-ideographic', 'hiragana', 'katakana', 'hiragana-iroha', 'katakana-iroha',
  'landscape', 'portrait', 'crop', 'cross', 'always', 'avoid', 'wider',
  'narrower', 'ultra-condensed', 'extra-condensed', 'condensed',
  'semi-condensed', 'semi-expanded', 'expanded', 'extra-expanded',
  'ultra-expanded', 'caption', 'icon', 'menu', 'message-box', 'small-caption',
  'status-bar', 'separate', 'show', 'hide', 'once', 'crosshair', 'default',
  'pointer', 'move', 'text', 'wait', 'help', 'e-resize', 'ne-resize',
  'nw-resize', 'n-resize', 'se-resize', 'sw-resize', 's-resize', 'w-resize',
  'ActiveBorder', 'ActiveCaption', 'AppWorkspace', 'Background', 'ButtonFace',
  'ButtonHighlight', 'ButtonShadow', 'InactiveCaptionText', 'ButtonText',
  'CaptionText', 'GrayText', 'Highlight', 'HighlightText', 'InactiveBorder',
  'InactiveCaption', 'InfoBackground', 'InfoText', 'Menu', 'MenuText',
  'Scrollbar', 'ThreeDDarkShadow', 'ThreeDFace', 'ThreeDHighlight',
  'ThreeDLightShadow', 'ThreeDShadow', 'Window', 'WindowFrame', 'WindowText',
  'silent', 'x-soft', 'soft', 'medium', 'loud', 'x-loud', 'spell-out', 'mix',
  'left-side', 'far-left', 'center-left', 'center-right', 'far-right',
  'right-side', 'behind', 'leftwards', 'rightwards', 'below', 'level', 'above',
  'higher', 'lower', 'x-slow', 'slow', 'medium', 'fast', 'x-fast', 'faster',
  'slower', 'male', 'female', 'child', 'x-low', 'low', 'high', 'x-high', 'code',
  'digits', 'continous'
}, '-')
local property = token('keyword', css1_property + css2_property)
local value = token('css_value', css1_value + css2_value)
local keyword = property + value

-- colors, units, numbers, and urls
local digit, xdigit = l.digit, l.xdigit
local hexcolor =
  token('css_color', '#' * xdigit * xdigit * xdigit *
        (xdigit * xdigit * xdigit)^-1)
local rgbunit = (digit^1 * P('%')^-1)
local rgbcolor =
  token('css_color', 'rgb(' * rgbunit * ',' * rgbunit * ',' * rgbunit * ')')
local color = hexcolor + rgbcolor
local unit = word_match {
  'pt', 'mm', 'cm', 'pc', 'in', 'px', 'em', 'ex', 'deg',
  'rad', 'grad', 'ms', 's', 'Hz', 'kHz'
}
unit = token('css_unit', unit + '%')
local css_float = digit^0 * '.' * digit^1 + digit^1 * '.' * digit^0 + digit^1
local number = token('number', S('+-')^-1 * css_float) * unit^-1
local url =
  token('css_url', 'url' * ('(' * (sq_str + dq_str) * ')' +
        l.delimited_range('()', '\\', true)))

-- declaration block
local block_default_char =
  token('default', (l.any - '}')^0) -- used to keep block colored properly
local property_value =
  value + string + number + color + url + token('default', word_char^1)
local property_values =
  { property_value * (ws * property_value)^0 * (ws^0 * comma * ws^0 * V(1))^0 }
local declaration_value =
  colon * ws^0 * property_values * ws^0 * (semicolon + block_default_char)
local declaration_property = property * ws^0
local declaration =
  (declaration_property * (declaration_value + block_default_char)) + comment +
    block_default_char
local declaration_block =
  obrace * ws^0 * declaration * (ws * declaration)^0 * ws^0 * cbrace^-1

local css_element = selector * ws^0 * declaration_block^-1

_rules = {
  { 'css_whitespace', ws },
  { 'comment', comment },
  { 'css_at_rule', at_rule },
  { 'string', string },
  { 'css_element', css_element },
  { 'any_char', l.any_char },
}

_tokenstyles = {
  { 'css_whitespace', l.style_nothing },
  { 'css_at_rule', l.style_predefinition },
  { 'css_selector', l.style_definition },
  { 'css_value', l.style_nothing..{ bold = true } },
  { 'css_unit', l.style_number },
  { 'css_color', l.style_number },
  { 'css_url', l.style_string },
}
