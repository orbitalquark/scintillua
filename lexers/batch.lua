-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Batch LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local rem = (P('REM') + 'rem') * space
local comment = token('comment', (rem + ':') * nonnewline^0)

-- strings
local string = token('string', delimited_range('"', '\\', true, false, '\n'))

-- keywords
local keyword = token('keyword', word_match(word_list{
  'cd', 'chdir', 'md', 'mkdir', 'cls', 'for', 'if', 'echo', 'echo.', 'move',
  'copy', 'move', 'ren', 'del', 'set', 'call', 'exit', 'setlocal', 'shift',
  'endlocal', 'pause', 'defined', 'exist', 'errorlevel', 'else', 'in', 'do',
  'NUL', 'AUX', 'PRN', 'not', 'goto',
}, nil, true))

-- functions
local func = token('function', word_match(word_list{
  'APPEND', 'ATTRIB', 'CHKDSK', 'CHOICE', 'DEBUG', 'DEFRAG', 'DELTREE',
  'DISKCOMP', 'DISKCOPY', 'DOSKEY', 'DRVSPACE', 'EMM386', 'EXPAND', 'FASTOPEN',
  'FC', 'FDISK', 'FIND', 'FORMAT', 'GRAPHICS', 'KEYB', 'LABEL', 'LOADFIX',
  'MEM', 'MODE', 'MORE', 'MOVE', 'MSCDEX', 'NLSFUNC', 'POWER', 'PRINT', 'RD',
  'REPLACE', 'RESTORE', 'SETVER', 'SHARE', 'SORT', 'SUBST', 'SYS', 'TREE',
  'UNDELETE', 'UNFORMAT', 'VSAFE', 'XCOPY',
}, nil, true))

-- identifiers
local identifier = token('identifier', word)

-- variables
local variable = token('variable', '%' * (digit + '%' * alpha) +
  delimited_range('%', nil, false, false, '\n'))

-- labels
local label = token('label', ':' * word)

-- operators
local operator = token('operator', S('+|&!<>='))

function LoadTokens()
  local batch = batch
  add_token(batch, 'whitespace', ws)
  add_token(batch, 'comment', comment)
  add_token(batch, 'string', string)
  add_token(batch, 'keyword', keyword)
  add_token(batch, 'function', func)
  add_token(batch, 'identifier', identifier)
  add_token(batch, 'variable', variable)
  add_token(batch, 'label', label)
  add_token(batch, 'operator', operator)
  add_token(batch, 'any_char', any_char)
end

-- line by line lexer
LexByLine = true
