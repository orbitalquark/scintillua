-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- AWK LPeg lexer.
-- Modified by Wolfgang Seeberg 2012.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = { _NAME = 'awk' }

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local comment = token(l.COMMENT, '#' * l.nonnewline^0)

-- Strings.
local string = token(l.STRING, l.delimited_range('"', '\\', true, false, '\n'))

-- Regular expressions.
local slashes = l.delimited_range('//', '\\', true, false, '\n')
-- Regular expressions are preceded by most operators or the
-- keywords 'print' and 'case', possibly on a preceding line.
local function isRegex(input, index)
  local i = index - 1
  while i >= 1 and input:find('^[ \t]', i) do i = i - 1 end
  if i < 1 then return true end
  local function findword(input, word, e)
    local s = e - #word + 1
    if s < 1 or input:sub(s, e) ~= word then
      return false
    else
      return s == 1 or not input:find("^[%w_$]", s - 1)
    end
  end
  if input:find("^[,([{~&|!=+%-/*<>?:^;}$%%]", i) or
     findword(input, 'case', i) or findword(input, 'print', i) then
    return true
  elseif input:find('^[]%w)."]', i) then
    return false
  elseif input:sub(i, i) == "\n" then
    if i == 1 then return true end
    i = i - 1
    if input:sub(i, i) == "\r" then
      if i == 1 then return true end
      i = i - 1
    end
  elseif input:sub(i, i) == "\r" then
    if i == 1 then return true end
    i = i - 1
  else
    return false
  end
  if input:sub(i, i) == "\\" then
    return isRegex(input, i)
  else
    return true
  end
end
-- not yet supported: /[/]/.
local regex = token('regex', P(isRegex) * slashes)

-- Numbers.
local number = token(l.NUMBER, l.float + l.integer)

-- Keywords.
local keyword = token(l.KEYWORD, word_match {
  'BEGIN', 'END', 'atan2', 'break', 'close', 'continue', 'cos', 'delete', 'do',
  'else', 'exit', 'exp', 'fflush', 'for', 'function', 'getline', 'gsub', 'if',
  'in', 'index', 'int', 'length', 'log', 'match', 'next', 'nextfile', 'print',
  'printf', 'rand', 'return', 'sin', 'split', 'sprintf', 'sqrt', 'srand', 'sub',
  'substr', 'system', 'tolower', 'toupper', 'while'
})

local gawkKeyword = token('gawkKeyword', word_match {
  'BEGINFILE', 'ENDFILE', 'adump', 'and', 'asort', 'asorti', 'bindtextdomain',
  'case', 'compl', 'dcgettext', 'dcngettext', 'default', 'extension', 'func',
  'gensub', 'include', 'isarray', 'lshift', 'mktime', 'or', 'patsplit',
  'rshift', 'stopme', 'strftime', 'strtonum', 'switch', 'systime', 'xor'
})

local builtInVariable = token('builtInVariable', word_match {
  'ARGC', 'ARGV', 'CONVFMT', 'ENVIRON', 'FILENAME', 'FNR', 'FS', 'NF', 'NR',
  'OFMT', 'OFS', 'ORS', 'RLENGTH', 'RS', 'RSTART', 'SUBSEP'
})

local gawkBuiltInVariable = token('gawkBuiltInVariable', word_match {
  'ARGIND', 'BINMODE', 'ERRNO', 'FIELDWIDTHS', 'FPAT', 'IGNORECASE', 'LINT',
  'PROCINFO', 'RT', 'TEXTDOMAIN'
})

-- Operators.
local operator = token(l.OPERATOR, S('=!<>+-*/%&|^~,:;()[]{}\\'))

local gawkOperator = token('gawkOperator', P("|&") + P("@"))

-- Field variables.
local fieldVariable = token('fieldVariable', '$' * (l.word + l.digit)^0)
local parens = l.delimited_range('()', '\\', true, true, '"/\n')
-- e.g. $(NF-2).
-- not yet supported: $(length("a)))b")).
local fieldVariableInParens = token('fieldVariableInParens', '$' * parens)

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

M._rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'gawkKeyword', gawkKeyword },
  { 'builtInVariable', builtInVariable },
  { 'gawkBuiltInVariable', gawkBuiltInVariable },
  { 'identifier', identifier },
  { 'comment', comment },
  { 'number', number },
  { 'string', string },
  { 'regex', regex },
  { 'fieldVariableInParens', fieldVariableInParens },
  { 'fieldVariable', fieldVariable },
  { 'gawkOperator', gawkOperator },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

M._tokenstyles = {
  { 'builtInVariable', l.style_constant },
  { 'fieldVariable', l.style_label },
  { 'fieldVariableInParens', l.style_label },
  { 'gawkBuiltInVariable', l.style_constant .. { underline = true } },
  { 'gawkKeyword', l.style_keyword .. { underline = true } },
  { 'gawkOperator', l.style_operator .. { underline = true } },
  { 'regex', l.style_preproc },
}

M._foldsymbols = {
  _patterns = { '[{}]', '#' },
  [l.OPERATOR] = { ['{'] = 1, ['}'] = -1 },
  [l.COMMENT] = { ['#'] = l.fold_line_comments('#') }
}

return M
