-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- VisualBasic LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', (P("'") + 'REM ') * nonnewline^0)

-- strings
local string = token('string', delimited_range('"', nil, true, false, '\n'))

-- numbers
local number = token('number', (float + integer) * S('LlUuFf')^-2)

-- keywords
local keyword = token('keyword', word_match(word_list{
  -- control
  'If', 'Then', 'Else', 'ElseIf', 'EndIf', 'While', 'Went', 'For', 'To', 'Each',
  'In', 'Step', 'Case', 'Select', 'EndSelect', 'Return', 'Continue', 'Do',
  'Until', 'Loop', 'Next', 'With', 'Exit',
  -- operators
  'Mod', 'And', 'Not', 'Or', 'Xor', 'Is',
  -- storage types
  'Call', 'Class', 'Const', 'Dim', 'Redim', 'Function', 'Sub', 'Property',
  'End', 'Set', 'Let', 'Get', 'New', 'Randomize',
  -- storage modifiers
  'Private', 'Public', 'Default',
  -- constants
  'Empty', 'False', 'Nothing', 'Null', 'True'
}))

-- types
local type = token('type', word_match(word_list{
  'Boolean', 'Byte', 'Char', 'Date', 'Decimal', 'Double', 'Long', 'Object',
  'Short', 'Single', 'String'
}))

-- identifier
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('=><+-*^&:.,_()'))

function LoadTokens()
  local vb = vb
  add_token(vb, 'whitespace', ws)
  add_token(vb, 'comment', comment)
  add_token(vb, 'string', string)
  add_token(vb, 'number', number)
  add_token(vb, 'keyword', keyword)
  add_token(vb, 'type', type)
  add_token(vb, 'identifier', identifier)
  add_token(vb, 'operator', operator)
  add_token(vb, 'any_char', any_char)

  -- embedding VB in another language
  if hypertext then
    local html = hypertext
    local tag = html.TokenPatterns.tag
    local case_insensitive = html.case_insensitive_tags
    -- search for something of the form <script language="vbscript">
    local script_element = word_match(word_list{'script'}, nil, case_insensitive_tags)
    start_token = #(P('<') * script_element *
      P(function(input, index)
        if input:find('[^>]+language%s*=%s*(["\'])vbscript%1') then return index end
      end)) * tag -- color tag normally, and tag passes for start_token
    end_token = #('</' * script_element * ws^0 * '>') * tag -- </script>
    vb.TokenPatterns.operator = token('operator', S('=>+-*^&:.,_()')) +
      '<' * -('/' * script_element)
    vb.TokenPatterns.any_char = token('vb_default', any - end_token)
    make_embeddable(vb, html, start_token, end_token)
  end
end
