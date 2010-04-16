-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Batch LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local rem = (P('REM') + 'rem') * l.space
local comment = token('comment', (rem + ':') * l.nonnewline^0)

-- strings
local string = token('string', l.delimited_range('"', '\\', true, false, '\n'))

-- keywords
local keyword = token('keyword', word_match({
  'cd', 'chdir', 'md', 'mkdir', 'cls', 'for', 'if', 'echo', 'echo.', 'move',
  'copy', 'move', 'ren', 'del', 'set', 'call', 'exit', 'setlocal', 'shift',
  'endlocal', 'pause', 'defined', 'exist', 'errorlevel', 'else', 'in', 'do',
  'NUL', 'AUX', 'PRN', 'not', 'goto',
}, nil, true))

-- functions
local func = token('function', word_match({
  'APPEND', 'ATTRIB', 'CHKDSK', 'CHOICE', 'DEBUG', 'DEFRAG', 'DELTREE',
  'DISKCOMP', 'DISKCOPY', 'DOSKEY', 'DRVSPACE', 'EMM386', 'EXPAND', 'FASTOPEN',
  'FC', 'FDISK', 'FIND', 'FORMAT', 'GRAPHICS', 'KEYB', 'LABEL', 'LOADFIX',
  'MEM', 'MODE', 'MORE', 'MOVE', 'MSCDEX', 'NLSFUNC', 'POWER', 'PRINT', 'RD',
  'REPLACE', 'RESTORE', 'SETVER', 'SHARE', 'SORT', 'SUBST', 'SYS', 'TREE',
  'UNDELETE', 'UNFORMAT', 'VSAFE', 'XCOPY',
}, nil, true))

-- identifiers
local identifier = token('identifier', l.word)

-- variables
local variable = token('variable', '%' * (l.digit + '%' * l.alpha) +
  l.delimited_range('%', nil, false, false, '\n'))

-- labels
local label = token('label', ':' * l.word)

-- operators
local operator = token('operator', S('+|&!<>='))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'function', func },
  { 'comment', comment },
  { 'identifier', identifier },
  { 'string', string },
  { 'variable', variable },
  { 'label', label },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

_tokenstyles = {
  { 'label', l.style_constant },
}

_LEXBYLINE = true
