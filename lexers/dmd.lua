-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- D LPeg Lexer

-- Modified by Brian Schott (SirAlaran)

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = '//' * nonnewline_esc^0
local block_comment = '/*' * (any - '*/')^0 * P('*/')^-1
local nested_comment = nested_pair('/+', '+/', true)
local comment = token('comment', line_comment + block_comment + nested_comment)

-- strings
local sq_str = delimited_range("'", '\\', true, false, '\n')
local dq_str = delimited_range('"', '\\', true, false, '\n')
local lit_str = 'r' * delimited_range('"', nil, true, false, '\n')
local bt_str = delimited_range('`', '\\', nil, false, '\n')
local hex_str = 'x' * delimited_range('"', '\\', nil, false, '\n')
local string = token('string', sq_str + dq_str + lit_str + bt_str + hex_str)

-- numbers
local dec = digit^1 * ('_' * digit^1)^0
local bin_num = '0' * S('bB') * S('01_')^1
local oct_num = '0' * S('01234567_')^1
local integer = S('+-')^-1 * (hex_num + oct_num + bin_num + dec)
local number = token('number', (float + integer) * S('uUlLdDfFi')^-1)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'abstract', 'align', 'asm', 'assert', 'auto', 'body', 'break', 'case', 'cast',
  'catch', 'const', 'continue', 'debug', 'default', 'delegate', 'delete',
  'deprecated', 'do', 'else', 'extern', 'false', 'final', 'finally', 'for',
  'foreach', 'function', 'goto', 'if', 'import', 'immutable', 'in', 'inout',
  'invariant', 'is', 'mixin', 'new', 'null', 'out', 'override', 'pragma',
  'private', 'protected', 'public', 'return', 'scope', 'shared', 'static',
  'super', 'switch', 'synchronized', 'this', 'throw','true', 'try', 'typeid',
  'typeof', 'unittest', 'version', 'volatile', 'while', 'with',
}))

-- types
local type = token('type', word_match(word_list{
  'alias', 'bool', 'byte', 'cdouble', 'cent', 'cfloat', 'char', 'class',
  'creal', 'dchar', 'double', 'enum', 'export', 'float', 'idouble', 'ifloat',
  'int', 'interface', 'ireal', 'long', 'module', 'package', 'ptrdiff_t', 'real',
  'short', 'size_t', 'struct', 'template', 'typedef', 'ubyte', 'ucent', 'uint',
  'ulong', 'union', 'ushort', 'void', 'wchar'
}))

-- constants
local constant = token('constant', word_match(word_list{
  '__FILE__', '__LINE__', '__DATE__', '__TIME__', '__TIMESTAMP__', '__VENDOR__',
  '__VERSION__', 'DigitalMars', 'X86', 'X86_64', 'Windows', 'Win32', 'Win64',
  'linux', 'Posix', 'LittleEndain', 'BigEndain', 'D_Coverage',
  'D_InlineAsm_X86', 'D_InlineAsm_X86_64', 'D_LP64', 'D_PIC', 'unittest',
  'D_Version2', 'all'
}))

local class_sequence = token('keyword', P('class')) * ws^1 * token('class', alpha * alnum^0)

-- identifiers
local identifier = token('identifier', word)

local operator_overloads = token('function', word_match(word_list{
	'opNeg', 'opPos', 'opCom', 'opStar', 'opPostInc', 'opPostDec', 'opCast',
	'opAdd', 'opAdd_r', 'opSub', 'opSub_r', 'opMul', 'opMul_r', 'opDiv',
	'opDiv_r', 'opMod', 'opMod_r', 'opAnd', 'opAnd_r', 'opOr', 'opOr_r',
	'opXor', 'opXor_r', 'opShl', 'opShl_r', 'opShr', 'opShr_r', 'opUShr',
	'opUShr_r', 'opCat', 'opCat_r', 'opEquals', 'opCmp', 'opAssign',
	'opAddAssign', 'opSubAssign', 'opMulAssign', 'opDivAssign', 'opModAssign',
	'opAndAssign', 'opOrAssign', 'opXorAssign', 'opShlAssign', 'opShrAssign',
	'opUShrAssign', 'opCatAssign', 'opIn', 'opIn_r'
}))

-- operators
local operator = token('operator', S('=!<>+-*/%&|^~.,;()[]{}'))

-- properties
local properties = (type + identifier + operator ) * token('operator', '.') * token('variable', word_match(word_list{
	'alignof', 'dig', 'dup', 'epsilon', 'idup', 'im', 'init', 'infinity',
	'keys', 'length', 'mangleof', 'mant_dig', 'max', 'max_exp', 'min',
	'min_10_exp', 'min_exp', 'nan', 'offsetof', 'ptr', 're', 'rehash',
	'reverse', 'sizeof', 'sort', 'stringof', 'tupleof', 'values'
}))

function LoadTokens()
  local d = d
--  add_token(dmd, 'error', error)
  add_token(dmd, 'whitespace', ws)
  add_token(dmd, 'class', class_sequence)
  add_token(dmd, 'keyword', keyword)
  add_token(dmd, 'variable', properties)
  add_token(dmd, 'function', operator_overloads)
  add_token(dmd, 'type', type)
  add_token(dmd, 'constant', constant)
  add_token(dmd, 'string', string)
  add_token(dmd, 'identifier', identifier)
  add_token(dmd, 'comment', comment)
  add_token(dmd, 'number', number)
  add_token(dmd, 'operator', operator)
  add_token(dmd, 'any_char', any_char)
end

function LoadStyles()
  add_style('annotation', style_preproc)
end
