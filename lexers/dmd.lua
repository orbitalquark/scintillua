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
  'private', 'protected', 'public', 'pure', 'ref', 'return', 'scope', 'shared',
  'static', 'super', 'switch', 'synchronized', 'this', 'throw','true', 'try',
  'typeid', 'typeof', 'unittest', 'version', 'volatile', 'while', 'with',
}))

-- types
local type = token('type', word_match(word_list{
  'alias', 'bool', 'byte', 'cdouble', 'cent', 'cfloat', 'char', 'class',
  'creal', 'dchar', 'double', 'enum', 'export', 'float', 'idouble', 'ifloat',
  'int', 'interface', 'ireal', 'long', 'module', 'package', 'ptrdiff_t', 'real',
  'short', 'size_t', 'struct', 'template', 'typedef', 'ubyte', 'ucent', 'uint',
  'ulong', 'union', 'ushort', 'void', 'wchar', 'string', 'wstring', 'dstring'
}))

-- constants
local constant = token('constant', word_match(word_list{
  '__FILE__', '__LINE__', '__DATE__', '__TIME__', '__TIMESTAMP__', '__VENDOR__',
  '__VERSION__', 'DigitalMars', 'X86', 'X86_64', 'Windows', 'Win32', 'Win64',
  'linux', 'Posix', 'LittleEndain', 'BigEndain', 'D_Coverage',
  'D_InlineAsm_X86', 'D_InlineAsm_X86_64', 'D_LP64', 'D_PIC',
  'D_Version2', 'all'
}))

local class_sequence = token('keyword', P('class')) * ws^1 * token('class', alpha * alnum^0)

-- identifiers
local identifier = token('identifier', word)

local operator_overloads = token('function', word_match(word_list{
	'opAssign', 'opBinary', 'opCall', 'opCmp', 'opDispatch', 'opEquals',
	'opIndex', 'opIndexAssign', 'opIndexUnary', 'opOpAssign', 'opSlice',
	'opSliceAssign', 'opSliceOpAssign', 'opSliceUnary', 'opUnary',
}))

-- operators
local operator = token('operator', S('=!<>+-*$/%&|^~.,;()[]{}'))

-- properties
local properties = (type + identifier + operator ) * token('operator', '.') * token('variable', word_match(word_list{
	'alignof', 'dig', 'dup', 'epsilon', 'idup', 'im', 'init', 'infinity',
	'keys', 'length', 'mangleof', 'mant_dig', 'max', 'max_exp', 'min',
	'min_10_exp', 'min_exp', 'nan', 'offsetof', 'ptr', 're', 'rehash',
	'reverse', 'sizeof', 'sort', 'stringof', 'tupleof', 'values'
}))

-- preprocs
local annotation = token('annotation', '@' * word^1)

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
  add_token(dmd, 'annotation', annotation)
  add_token(dmd, 'any_char', any_char)
end

function LoadStyles()
  add_style('annotation', style_preproc)
end

function Fold(text, start_pos, start_line, start_level)
	local folds = {}
	local current_line = start_line
	local current_level = start_level
	local foldCause = -1 -- 0 = brace, 1 = comment
	for line in text:gmatch("(.-)\r?\n") do
		if #line > 0 then
			if line:find("{%s*$") and current_line ~= 1 then
				foldCause = 0
				folds[current_line] = {current_level, SC_FOLDLEVELHEADERFLAG}
				current_level = current_level + 1
			elseif line:find("/%*%s*") then
				foldCause = 1
				-- I have no idea why it tries to set the fold level header flag
				-- on lines 0 AND one when you set it on line 0... I also don't
				-- know why setting it on line -1 works.
				if current_line == 0 then
					folds[-1] = {current_level, SC_FOLDLEVELHEADERFLAG}
				else
					folds[current_line] = {current_level, SC_FOLDLEVELHEADERFLAG}
				end
				current_level = current_level + 1
			elseif line:find("}") and foldCause == 0 then
				current_level = current_level - 1
				folds[current_line] = {current_level}
			elseif line:find("%*/") and foldCause == 1 then
				current_level = current_level - 1
				folds[current_line] = {current_level}
			else
				folds[current_line] = {current_level}
			end
		else
			folds[current_line] = {current_level, SC_FOLDLEVELWHITEFLAG}
		end
		current_line = current_line + 1
	end
	return folds
end
