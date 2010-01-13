-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Rexx LPeg Lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = '--' * nonnewline_esc^0
local block_comment = nested_pair('/*', '*/', true)
local comment = token('comment', line_comment + block_comment)

-- strings
local sq_str = delimited_range("'", '\\', true, false, '\n')
local dq_str = delimited_range('"', '\\', true, false, '\n')
local string = token('string', sq_str + dq_str)

-- numbers
local number = token('number', float + integer)

-- preprocessor
local preproc = token('preprocessor', #P('#') * starts_line('#' * nonnewline^0))

-- keywords
local keyword = token('keyword', word_match(word_list{
  'address', 'arg', 'by', 'call', 'class', 'do', 'drop', 'else', 'end', 'exit',
  'expose', 'forever', 'forward', 'guard', 'if', 'interpret', 'iterate',
  'leave', 'method', 'nop', 'numeric', 'otherwise, ''parse', 'procedure',
  'pull', 'push', 'queue', 'raise', 'reply', 'requires', 'return', 'routine',
  'result', 'rc', 'say', 'select', 'self', 'sigl', 'signal', 'super', 'then',
  'to', 'trace', 'use', 'when', 'while', 'until'
}, nil, true))

-- functions
local func = token('function', word_match(word_list{
  'abbrev', 'abs', 'address', 'arg', 'beep', 'bitand', 'bitor', 'bitxor', 'b2x',
  'center', 'changestr', 'charin', 'charout', 'chars', 'compare', 'consition',
  'copies', 'countstr', 'c2d', 'c2x', 'datatype', 'date', 'delstr', 'delword',
  'digits', 'directory', 'd2c', 'd2x', 'errortext', 'filespec', 'form',
  'format', 'fuzz', 'insert', 'lastpos', 'left', 'length', 'linein', 'lineout',
  'lines', 'max', 'min', 'overlay', 'pos', 'queued', 'random', 'reverse',
  'right', 'sign', 'sourceline', 'space', 'stream', 'strip', 'substr',
  'subword', 'symbol', 'time', 'trace', 'translate', 'trunc', 'value', 'var',
  'verify', 'word', 'wordindex', 'wordlength', 'wordpos', 'words', 'xrange',
  'x2b', 'x2c', 'x2d', 'rxfuncadd', 'rxfuncdrop', 'rxfuncquery', 'rxmessagebox',
  'rxwinexec', 'sysaddrexxmacro', 'sysbootdrive', 'sysclearrexxmacrospace',
  'syscloseeventsem', 'sysclosemutexsem', 'syscls', 'syscreateeventsem',
  'syscreatemutexsem', 'syscurpos', 'syscurstate', 'sysdriveinfo',
  'sysdrivemap', 'sysdropfuncs', 'sysdroprexxmacro', 'sysdumpvariables',
  'sysfiledelete', 'sysfilesearch', 'sysfilesystemtype', 'sysfiletree',
  'sysfromunicode', 'systounicode', 'sysgeterrortext', 'sysgetfiledatetime',
  'sysgetkey', 'sysini', 'sysloadfuncs', 'sysloadrexxmacrospace', 'sysmkdir',
  'sysopeneventsem', 'sysopenmutexsem', 'sysposteventsem', 'syspulseeventsem',
  'sysqueryprocess', 'sysqueryrexxmacro', 'sysreleasemutexsem',
  'sysreorderrexxmacro', 'sysrequestmutexsem', 'sysreseteventsem', 'sysrmdir',
  'syssaverexxmacrospace', 'syssearchpath', 'syssetfiledatetime',
  'syssetpriority', 'syssleep', 'sysstemcopy', 'sysstemdelete', 'syssteminsert',
  'sysstemsort', 'sysswitchsession', 'syssystemdirectory', 'systempfilename',
  'systextscreenread', 'systextscreensize', 'sysutilversion', 'sysversion',
  'sysvolumelabel', 'syswaiteventsem', 'syswaitnamedpipe', 'syswindecryptfile',
  'syswinencryptfile', 'syswinver'
}, '2', true))

-- identifiers
local word = alpha * (alnum + S('@#$\\.!?_')^0)
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('=!<>+-/\\*%&|^~.,:;(){}'))

function LoadTokens()
  local rexx = rexx
  add_token(rexx, 'whitespace', ws)
  add_token(rexx, 'comment', comment)
  add_token(rexx, 'string', string)
  add_token(rexx, 'number', number)
  add_token(rexx, 'preproc', preproc)
  add_token(rexx, 'keyword', keyword)
  add_token(rexx, 'function', func)
  add_token(rexx, 'identifier', identifier)
  add_token(rexx, 'operator', operator)
  add_token(rexx, 'any_char', any_char)
end
