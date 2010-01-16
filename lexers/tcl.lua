-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- TCL LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', '#' * nonnewline^0)

-- strings
local sq_str = delimited_range("'", '\\', true, false, '\n')
local dq_str = delimited_range('"', '\\', true, false, '\n')
local regex = delimited_range('/', '\\', false, false, '\n')
local string = token('string', sq_str + dq_str + regex)

-- numbers
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'string', 'subst', 'regexp', 'regsub', 'scan', 'format', 'binary', 'list',
  'split', 'join', 'concat', 'llength', 'lrange', 'lsearch', 'lreplace',
  'lindex', 'lsort', 'linsert', 'lrepeat', 'dict', 'if', 'else', 'elseif',
  'then', 'for', 'foreach', 'switch', 'case', 'while', 'continue', 'return',
  'break', 'catch', 'error', 'eval', 'uplevel', 'after', 'update', 'vwait',
  'proc', 'rename', 'set', 'lset', 'lassign', 'unset', 'namespace', 'variable',
  'upvar', 'global', 'trace', 'array', 'incr', 'append', 'lappend', 'expr',
  'file', 'open', 'close', 'socket', 'fconfigure', 'puts', 'gets', 'read',
  'seek', 'tell', 'eof', 'flush', 'fblocked', 'fcopy', 'fileevent', 'source',
  'load', 'unload', 'package', 'info', 'interp', 'history', 'bgerror',
  'unknown', 'memory', 'cd', 'pwd', 'clock', 'time', 'exec', 'glob', 'pid',
  'exit'
}))

-- identifiers
local identifier = token('identifier', word)

-- variables
local variable = token('variable', S('$@$') * P('$')^-1 * word)

-- operators
local operator = token('operator', S('<>=+-*/!@|&.,:;?()[]{}'))

function LoadTokens()
  local tcl = tcl
  add_token(tcl, 'whitespace', ws)
  add_token(tcl, 'keyword', keyword)
  add_token(tcl, 'identifier', identifier)
  add_token(tcl, 'string', string)
  add_token(tcl, 'comment', comment)
  add_token(tcl, 'number', number)
  add_token(tcl, 'variable', variable)
  add_token(tcl, 'operator', operator)
  add_token(tcl, 'any_char', any_char)
end
