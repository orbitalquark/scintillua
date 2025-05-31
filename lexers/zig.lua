-- Copyright 2020-2025 Karchnu karchnu@karchnu.fr. See LICENSE.
-- Zig LPeg lexer.
-- (Based on the C++ LPeg lexer from Mitchell.)

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- Types.
lex:add_rule('type', lex:tag(lexer.TYPE, lex:word_match(lexer.TYPE)))

-- Constants.
lex:add_rule('constant', lex:tag(lexer.CONSTANT, lex:word_match(lexer.CONSTANT)))

-- Built-in functions.
lex:add_rule('function',
	lex:tag(lexer.FUNCTION_BUILTIN, '@' * lex:word_match(lexer.FUNCTION_BUILTIN)))

-- Strings.
local sq_str = lexer.range("'", true) -- Character/Byte literal
local dq_str = lexer.range('"', true) -- String/Byte array literal
lex:add_rule('string', lex:tag(lexer.STRING, sq_str + dq_str))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))

-- Comments.
local doc_comment = lexer.to_eol('///', true) -- Documentation comments
local comment = lexer.to_eol('//', true)     -- Single-line comments
lex:add_rule('comment', lex:tag(lexer.COMMENT, doc_comment + comment))

-- Numbers.
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number))

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('+-/*%<>!=^&|?~:;,.()[]{}')))

-- Word lists
lex:set_word_list(lexer.KEYWORD, {
	-- Keywords.
	'inline', 'pub', 'fn', 'comptime', 'const', 'extern', 'return', 'var', 'usingnamespace',
	-- Defering code blocks.
	'defer', 'errdefer',
	-- Functions and structures related keywords.
	'align', 'allowzero', 'noalias', 'noinline',
	'callconv', 'packed', 'linksection', 'unreachable', 'test', 'asm',
	'volatile',
	-- Parallelism and concurrency related keywords.
	'async', 'await', 'noasync', 'suspend', 'nosuspend', 'resume', 'threadlocalanyframe',
	-- Control flow: conditions and loops.
	'if', 'else', 'orelse', 'or', 'and', 'while', 'for', 'switch', 'continue', 'break', 'catch',
	'try',
	-- Not keyword but overly used variable name with always the same semantic.
	'self'
})

lex:set_word_list(lexer.TYPE, {
	'enum', 'struct', 'union', -- Aggregate types
	'i8', 'u8', 'i16', 'u16', 'i32', 'u32', 'i64', 'u64', 'i128', 'u128', -- Integer types
	'isize', 'usize', -- Pointer-sized integers
	'c_short', 'c_ushort', 'c_int', 'c_uint', -- C interop integer types
	'c_long', 'c_ulong', 'c_longlong', 'c_ulonglong', 'c_longdouble', -- More C interop types
	'c_void', -- C void type
	'f16', 'f32', 'f64', 'f128', -- Floating-point types
	'bool', 'void', 'noreturn', 'type', 'anytype', 'error', 'anyerror', -- Special types
	'addrspace', 'anyframe', 'anyopaque', 'opaque', 'threadlocal',
	'comptime_int', 'comptime_float' -- Comptime types
})

lex:set_word_list(lexer.FUNCTION_BUILTIN, {
	-- Extensive list of @-prefixed built-in functions
	'addWithOverflow', 'alignCast', 'alignOf', 'as', 'asyncCall', 'atomicLoad', 'atomicRmw',
	'atomicStore', 'bitCast', 'bitOffsetOf', 'boolToInt', 'bitSizeOf', 'breakpoint', 'mulAdd',
	'byteSwap', 'bitReverse', 'byteOffsetOf', 'call', 'cDefine', 'cImport', 'cInclude', 'clz',
	'cmpxchgStrong', 'cmpxchgWeak', 'compileError', 'compileLog', "constCast", 'ctz', 'cUndef',
	'divExact', 'divFloor', 'divTrunc', 'embedFile', 'enumToInt', "enumFromInt", "intFromEnum",
	"errorCast", 'errorName', 'errorReturnTrace', "errorFromInt", 'errorToInt', 'errSetCast',
	'export', 'fence', 'field', 'fieldParentPtr', 'floatCast',
	"floatFromInt", 'floatToInt', 'frame', 'Frame', 'frameAddress', 'frameSize',
	'hasDecl', 'hasField', 'import', "intFromBool", "intFromError", "intFromFloat",
	"inComptime", 'intCast', "intFromPtr", 'intToEnum', 'intToError', 'intToFloat', 'intToPtr',
	'memcpy', 'memset', 'wasmMemorySize', 'wasmMemoryGrow', 'mod', 'mulWithOverflow',
	"newStackCall", "offsetOf", "OpaqueType", 'panic', "prefetch",
	'popCount', 'ptrCast', "ptrFromInt", 'ptrToInt', 'reduce', 'rem', 'returnAddress', "select",
	'setAlignStack', 'setCold', 'setEvalBranchQuota', 'setFloatMode', 'setRuntimeSafety',
	'shlExact', 'shlWithOverflow', 'shrExact', 'shuffle', 'sizeOf', 'splat',
	'src', 'sqrt', 'sin', 'cos', 'tan', 'exp', 'exp2', 'log', 'log2', 'log10',
	'max', 'min', 'abs', 'fabs', 'floor', 'ceil', 'trap', 'trunc', 'round',
	'subWithOverflow', 'tagName', 'TagType', 'This', 'truncate',
	'Type', 'typeInfo', 'typeName', 'TypeOf', 'unionInit', 'Vector', 'volatileCast'
})

-- Strings.
local sq_str = P('L')^-1 * lexer.range("'", true)
local dq_str = P('L')^-1 * lexer.range('"', true)
lex:add_rule('string', token(lexer.STRING, sq_str + dq_str))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Comments.
local doc_comment = lexer.to_eol('///', true)
local comment = lexer.to_eol('//', true)
lex:add_rule('comment', token(lexer.COMMENT, doc_comment + comment))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.number))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, '..' + S('+-/*%<>!=^&|?~:;,.()[]{}')))

-- Special values.
lex:set_word_list(lexer.CONSTANT, {
	'false', 'true', 'null', 'undefined'
})

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')

lexer.property['scintillua.comment'] = '//'

return lex
