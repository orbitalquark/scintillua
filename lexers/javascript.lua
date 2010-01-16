-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- JavaScript LPeg Lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('js_whitespace', space^1)

local newline = #S('\r\n\f') * P(function(input, idx)
  if input:sub(idx - 1, idx - 1) ~= '\\' then return idx end
end) * S('\r\n\f')^1

-- comments
local line_comment = '//' * nonnewline_esc^0
local block_comment = '/*' * (any - '*/')^0 * P('*/')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local sq_str = delimited_range("'", '\\', true)
local dq_str = delimited_range('"', '\\', true)
local regex_str = delimited_range('/', '\\', nil, nil, '\n') * S('igm')^0
local string = token('string', sq_str + dq_str) + token('regex', regex_str)

-- numbers
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'abstract', 'boolean', 'break', 'byte', 'case', 'catch', 'char',
  'class', 'const', 'continue', 'debugger', 'default', 'delete',
  'do', 'double', 'else', 'enum', 'export', 'extends', 'false',
  'final', 'finally', 'float', 'for', 'function', 'goto', 'if',
  'implements', 'import', 'in', 'instanceof', 'int', 'interface',
  'let', 'long', 'native', 'new', 'null', 'package', 'private',
  'protected', 'public', 'return', 'short', 'static', 'super',
  'switch', 'synchronized', 'this', 'throw', 'throws', 'transient',
  'true', 'try', 'typeof', 'var', 'void', 'volatile', 'while',
  'with', 'yield'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('+-/*%^!=&|?:;.()[]{}<>'))

function LoadTokens()
  local javascript = javascript
  add_token(javascript, 'js_whitespace', ws)
  add_token(javascript, 'keyword', keyword)
  add_token(javascript, 'identifier', identifier)
  add_token(javascript, 'comment', comment)
  add_token(javascript, 'number', number)
  add_token(javascript, 'string', string)
  add_token(javascript, 'operator', operator)
  add_token(javascript, 'any_char', any_char)

  -- embedding JS in another language
  if hypertext then
    local html = hypertext
    local tag = html.TokenPatterns.tag
    local case_insensitive = html.case_insensitive_tags
    -- search for something of the form <script type="text/javascript">
    local script_element = word_match(word_list{'script'}, nil, case_insensitive_tags)
    start_token = #(P('<') * script_element *
      P(function(input, index)
        if input:find('[^>]+type%s*=%s*(["\'])text/javascript%1') then return index end
      end)) * tag -- color tag normally, and tag passes for start_token
    end_token = #('</' * script_element * ws^0 * '>') * tag -- </script>
    javascript.TokenPatterns.operator = token('operator', S('+-/*%^!=&|?:;.()[]{}>')) +
      '<' * -('/' * script_element)
    javascript.TokenPatterns.any_char = token('js_default', any - end_token)
    make_embeddable(javascript, html, start_token, end_token)
  end
end

function LoadStyles()
  if hypertext then -- embedded in HTML
    add_style('js_whitespace', style_nothing)
    add_style('js_default', style_nothing)
  end
  add_style('regex', style_string..{ back = color('44', '44', '44') })
end
