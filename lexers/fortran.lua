-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Fortran LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local c_comment = #S('Cc') * starts_line(S('Cc') * nonnewline^0)
local d_comment = #S('Dd') * starts_line(S('Dd') * nonnewline^0)
local ex_comment = #P('!') * starts_line('!' * nonnewline^0)
local ast_comment = #P('*') * starts_line('*' * nonnewline^0)
local line_comment = '!' * nonnewline^0
local comment = token('comment', c_comment + d_comment + ex_comment +
  ast_comment + line_comment)

-- strings
local sq_str = delimited_range("'", nil, true, false, '\n')
local dq_str = delimited_range('"', nil, true, false, '\n')
local string = token('string', sq_str + dq_str)

-- numbers
local number = token('number', (float + integer) * -alpha)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'include', 'program', 'module', 'subroutine', 'function', 'contains', 'use',
  'call', 'return',
  -- statements
  'case', 'select', 'default', 'continue', 'cycle', 'do', 'while', 'else', 'if',
  'elseif', 'then', 'elsewhere', 'end', 'endif', 'enddo', 'forall', 'where',
  'exit', 'goto', 'pause', 'stop',
  -- operators
  '.not.', '.and.', '.or.', '.xor.', '.eqv.', '.neqv.', '.eq.', '.ne.', '.gt.',
  '.ge.', '.lt.', '.le.',
  -- logical
  '.false.', '.true.'
}, '.', true))

-- functions
local func = token('function', word_match(word_list{
  -- i/o
  'backspace', 'close', 'endfile', 'inquire', 'open', 'print', 'read', 'rewind',
  'write', 'format',
  -- type conversion, utility, math
  'aimag', 'aint', 'amax0', 'amin0', 'anint', 'ceiling', 'cmplx', 'conjg',
  'dble', 'dcmplx', 'dfloat', 'dim', 'dprod', 'float', 'floor', 'ifix', 'imag',
  'int', 'logical', 'modulo', 'nint', 'real', 'sign', 'sngl', 'transfer',
  'zext', 'abs', 'acos', 'aimag', 'aint', 'alog', 'alog10', 'amax0', 'amax1',
  'amin0', 'amin1', 'amod', 'anint', 'asin', 'atan', 'atan2', 'cabs', 'ccos',
  'char', 'clog', 'cmplx', 'conjg', 'cos', 'cosh', 'csin', 'csqrt', 'dabs',
  'dacos', 'dasin', 'datan', 'datan2', 'dble', 'dcos', 'dcosh', 'ddim', 'dexp',
  'dim', 'dint', 'dlog', 'dlog10', 'dmax1', 'dmin1', 'dmod', 'dnint', 'dprod',
  'dreal', 'dsign', 'dsin', 'dsinh', 'dsqrt', 'dtan', 'dtanh', 'exp', 'float',
  'iabs', 'ichar', 'idim', 'idint', 'idnint', 'ifix', 'index', 'int', 'isign',
  'len', 'lge', 'lgt', 'lle', 'llt', 'log', 'log10', 'max', 'max0', 'max1',
  'min', 'min0', 'min1', 'mod', 'nint', 'real', 'sign', 'sin', 'sinh', 'sngl',
  'sqrt', 'tan', 'tanh'
}, nil, true))

-- types
local type = token('type', word_match(word_list{
  'implicit', 'explicit', 'none', 'data', 'parameter', 'allocate',
  'allocatable', 'allocated', 'deallocate', 'integer', 'real', 'double',
  'precision', 'complex', 'logical', 'character', 'dimension', 'kind',
}, nil, true))

-- identifiers
local identifier = token('identifier', alnum^1)

-- operators
local operator = token('operator', S('<>=&+-/*,()'))

function LoadTokens()
  local fortran = fortran
  add_token(fortran, 'whitespace', ws)
  add_token(fortran, 'comment', comment)
  add_token(fortran, 'string', string)
  add_token(fortran, 'number', number)
  add_token(fortran, 'keyword', keyword)
  add_token(fortran, 'function', func)
  add_token(fortran, 'type', type)
  add_token(fortran, 'identifier', identifier)
  add_token(fortran, 'operator', operator)
  add_token(fortran, 'any_char', any_char)
end
