-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Ruby LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local line_comment = '#' * l.nonnewline_esc^0
local block_comment = #P('=begin') * l.starts_line('=begin' * (l.any - l.newline * '=end')^0 * (l.newline * '=end')^-1)
local comment = token('comment', block_comment + line_comment)

local delimiter_matches = { ['('] = ')', ['['] = ']', ['{'] = '}' }
local literal_delimitted = P(function(input, index)
  local delimiter = input:sub(index, index)
  if not delimiter:find('[%w\r\n\f\t ]') then -- only non alpha-numerics
    local match_pos, patt
    if delimiter_matches[delimiter] then -- handle nested delimiter/matches in strings
      local s, e = delimiter, delimiter_matches[delimiter]
      patt = l.delimited_range(s..e, '\\', true, true)
    else
      patt = l.delimited_range(delimiter, '\\', true)
    end
    match_pos = l.lpeg.match(patt, input, index)
    return match_pos or #input + 1
  end
end)

-- strings
local cmd_str = l.delimited_range('`', '\\', true)
local lit_cmd = '%x' * literal_delimitted
local regex_op = S('iomx')^0
local regex_str = l.delimited_range('/', '\\', nil, nil, '\n') * regex_op
local lit_regex = '%r' * literal_delimitted * regex_op
local lit_array = '%w' * literal_delimitted
local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local lit_str = '%' * S('qQ')^-1 * literal_delimitted
local heredoc = '<<' * P(function(input, index)
  local s, e, indented, _, delimiter = input:find('(%-?)(["`]?)([%a_][%w_]*)%2[\n\r\f;]+', index)
  if s == index and delimiter then
    local end_heredoc = (#indented > 0 and '[\n\r\f]+ *' or '[\n\r\f]+')
    local _, e = input:find(end_heredoc..delimiter, e)
    return e and e + 1 or #input + 1
  end
end)
local string = token('string', sq_str + dq_str + lit_str + heredoc +
  cmd_str + lit_cmd + regex_str + lit_regex + lit_array)

local word_char = l.alnum + S('_!?')

-- numbers
local dec = l.digit^1 * ('_' * l.digit^1)^0
local bin = '0b' * S('01')^1 * ('_' * S('01')^1)^0
local integer = S('+-')^-1 * (bin + l.hex_num + l.oct_num + dec)
local numeric_literal = '?' * (l.any - l.space) * -word_char -- TODO: meta, control, etc.
local number = token('number', l.float + integer + numeric_literal)

-- keywords
local keyword = token('keyword', word_match({
  'BEGIN', 'END', 'alias', 'and', 'begin', 'break', 'case', 'class', 'def',
  'defined?', 'do', 'else', 'elsif', 'end', 'ensure', 'false', 'for', 'if',
  'in', 'module', 'next', 'nil', 'not', 'or', 'redo', 'rescue', 'retry',
  'return', 'self', 'super', 'then', 'true', 'undef', 'unless', 'until', 'when',
  'while', 'yield', '__FILE__', '__LINE__'
}, '?!'))

-- functions
local func = token('function', word_match({
  'at_exit', 'autoload', 'binding', 'caller', 'catch', 'chop', 'chop!', 'chomp',
  'chomp!', 'eval', 'exec', 'exit', 'exit!', 'fail', 'fork', 'format', 'gets',
  'global_variables', 'gsub', 'gsub!', 'iterator?', 'lambda', 'load',
  'local_variables', 'loop', 'open', 'p', 'print', 'printf', 'proc', 'putc',
  'puts', 'raise', 'rand', 'readline', 'readlines', 'require', 'select',
  'sleep', 'split', 'sprintf', 'srand', 'sub', 'sub!', 'syscall', 'system',
  'test', 'trace_var', 'trap', 'untrace_var'
}, '?!')) * -S('.:|')

-- identifiers
local word = (l.alpha + '_') * word_char^0
local identifier = token('identifier', word)

-- variables and symbols
local global_var = '$' * (word + S('!@L+`\'=~/\\,.;<>_*"$?:') + l.digit + '-' * S('0FadiIKlpvw'))
local class_var = '@@' * word
local inst_var = '@' * word
local symbol = ':' * P(function(input, index)
  if input:sub(index - 2, index - 2) ~= ':' then return index end
end) * (word_char^1 + sq_str + dq_str)
local variable = token('variable', global_var + class_var + inst_var + symbol)

-- operators
local operator = token('operator', S('!%^&*()[]{}-=+/|:;.,?<>~'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'function', func },
  { 'identifier', identifier },
  { 'comment', comment },
  { 'string', string },
  { 'number', number },
  { 'variable', variable },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
