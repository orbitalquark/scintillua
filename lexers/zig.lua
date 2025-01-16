-- Copyright 2020-2025 Karchnu karchnu@karchnu.fr. See LICENSE.
-- Zig LPeg lexer.
-- (Based on the C++ LPeg lexer from Mitchell.)

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))
lex:set_word_list(lexer.KEYWORD, {
	-- Keywords.
	'inline', 'pub', 'fn', 'comptime', 'const', 'extern', 'return', 'var', 'usingnamespace',
	-- Defering code blocks.
	'defer', 'errdefer',
	-- Functions and structures related keywords.
	'align', 'allowzero', 'noalias', 'noinline', 'callconv', 'packed', 'linksection', 'unreachable',
	'test', 'asm', 'volatile',
	-- Parallelism and concurrency related keywords.
	'async', 'await', 'noasync', 'suspend', 'nosuspend', 'resume', 'threadlocalanyframe',
	-- Control flow: conditions and loops.
	'if', 'else', 'orelse', 'or', 'and', 'while', 'for', 'switch', 'continue', 'break', 'catch',
	'try',
	-- Not keyword but overly used variable name with always the same semantic.
	'self'
})

-- Types.
lex:add_rule('type', lex:tag(lexer.TYPE, lex:word_match(lexer.TYPE)))
lex:set_word_list(lexer.TYPE, {
	'enum', 'struct', 'union', --
	'i8', 'u8', 'i16', 'u16', 'i32', 'u32', 'i64', 'u64', 'i128', 'u128', --
	'isize', 'usize', --
	'c_short', 'c_ushort', 'c_int', 'c_uint', --
	'c_long', 'c_ulong', 'c_longlong', 'c_ulonglong', 'c_longdouble', --
	'c_void', --
	'f16', 'f32', 'f64', 'f128', --
	'bool', 'void', 'noreturn', 'type', 'anytype', 'error', 'anyerror', --
	'comptime_int', 'comptime_float'
})

-- Constants.
lex:add_rule('constant', lex:tag(lexer.CONSTANT, lex:word_match(lexer.CONSTANT)))
-- Special values.
lex:set_word_list(lexer.CONSTANT, {
	'false', 'true', 'null', 'undefined'
})

-- Built-in functions.
lex:add_rule('function', lex:tag(lexer.FUNCTION, '@' * lex:word_match(lexer.FUNCTION)))
lex:set_word_list(lexer.FUNCTION, {
	'addWithOverflow', 'alignCast', 'alignOf', 'as', 'asyncCall', 'atomicLoad', 'atomicRmw',
	'atomicStore', 'bitCast', 'bitOffsetOf', 'boolToInt', 'bitSizeOf', 'breakpoint', 'mulAdd',
	'byteSwap', 'bitReverse', 'byteOffsetOf', 'call', 'cDefine', 'cImport', 'cInclude', 'clz',
	'cmpxchgStrong', 'cmpxchgWeak', 'compileError', 'compileLog', 'ctz', 'cUndef', 'divExact',
	'divFloor', 'divTrunc', 'embedFile', 'enumToInt', 'errorName', 'errorReturnTrace', 'errorToInt',
	'errSetCast', 'export', 'fence', 'field', 'fieldParentPtr', 'floatCast', 'floatToInt', 'frame',
	'Frame', 'frameAddress', 'frameSize', 'hasDecl', 'hasField', 'import', 'intCast', 'intToEnum',
	'intToError', 'intToFloat', 'intToPtr', 'memcpy', 'memset', 'wasmMemorySize', 'wasmMemoryGrow',
	'mod', 'mulWithOverflow', 'panic', 'popCount', 'ptrCast', 'ptrToInt', 'rem', 'returnAddress',
	'setAlignStack', 'setCold', 'setEvalBranchQuota', 'setFloatMode', 'setRuntimeSafety', 'shlExact',
	'shlWithOverflow', 'shrExact', 'shuffle', 'sizeOf', 'splat', 'reduce', 'src', 'sqrt', 'sin',
	'cos', 'exp', 'exp2', 'log', 'log2', 'log10', 'fabs', 'floor', 'ceil', 'trunc', 'round',
	'subWithOverflow', 'tagName', 'TagType', 'This', 'truncate', 'Type', 'typeInfo', 'typeName',
	'TypeOf', 'unionInit'
})

-- Strings.
local sq_str = P('L')^-1 * lexer.range("'", true)
local dq_str = P('L')^-1 * lexer.range('"', true)
lex:add_rule('string', lex:tag(lexer.STRING, sq_str + dq_str))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))

-- Comments.
local doc_comment = lexer.to_eol('///', true)
local comment = lexer.to_eol('//', true)
lex:add_rule('comment', lex:tag(lexer.COMMENT, doc_comment + comment))

-- Numbers.
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number))

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('+-/*%<>!=^&|?~:;,.()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')

lexer.property['scintillua.comment'] = '//'

return lex
