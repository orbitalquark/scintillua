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
lex:add_rule('constant', lex:tag(lexer.CONSTANT_BUILTIN, lex:word_match(lexer.CONSTANT_BUILTIN)))

-- Built-in functions.
lex:add_rule('function',
	lex:tag(lexer.FUNCTION_BUILTIN, '@' * lex:word_match(lexer.FUNCTION_BUILTIN)))

-- Bare functions (function calls without @).
lex:add_rule('function_call',
	lex:tag(lexer.FUNCTION, lexer.word * #(lexer.space^0 * '(')))

-- Struct methods (word followed by dot and another word).
lex:add_rule('method', lex:tag(lexer.FUNCTION_METHOD, lexer.word * '.' * lexer.word))

-- Strings.
local raw_str = lexer.to_eol('\\\\') -- Line strings
local sq_str = lexer.range("'", true) -- Character/Byte literal
local dq_str = lexer.range('"', true) -- String/Byte array literal
lex:add_rule('string', lex:tag(lexer.STRING, raw_str + sq_str + dq_str))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))

-- Comments.
local doc_comment = lexer.to_eol('///', true) -- Documentation comments
local comment = lexer.to_eol('//', true)     -- Single-line comments
lex:add_rule('comment', lex:tag(lexer.COMMENT, doc_comment + comment))

-- Numbers.
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number_('_')))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, '..' + S('+-/*%<>!=^&|?~:;,.()[]{}')))

-- Word lists
lex:set_word_list(lexer.KEYWORD, {
	-- Keywords.
	'inline', 'pub', 'fn', 'comptime', 'const', 'return', 'var', 'usingnamespace',
	-- Defering code blocks.
	'defer', 'errdefer',
	-- Functions and structures related keywords.
	'align', 'allowzero', 'noalias', 'noinline',
	'callconv', 'packed', 'linksection', 'unreachable', 'test', 'asm',
	'volatile',
	-- Parallelism and concurrency related keywords.
	'async', 'await', 'noasync', 'suspend', 'nosuspend', 'resume', 'threadlocal', 'anyframe',
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

-- https://ziglang.org/documentation/master/#Builtin-Functions
lex:set_word_list(lexer.FUNCTION_BUILTIN, {
	'addrSpaceCast', 'addWithOverflow', 'alignCast', 'alignOf', 'as', 'atomicLoad', 'atomicRmw',
	'atomicStore', 'bitCast', 'bitOffsetOf', 'bitSizeOf', 'branchHint', 'breakpoint', 'mulAdd',
	'byteSwap', 'bitReverse', 'call', 'cDefine', 'cImport', 'cInclude', 'clz', 'cmpxchgStrong',
	'cmpxchgWeak', 'compileError', 'compileLog', 'constCast', 'ctz', 'cUndef',
	'cVaArg', 'cVaCopy', 'cVaEnd', 'cVaStart', 'divExact', 'divFloor', 'divTrunc', 'embedFile',
	'enumToInt', 'enumFromInt', 'intFromEnum', 'errorCast', 'errorName', 'errorReturnTrace',
	'errorFromInt', 'export', 'extern', 'field', 'fieldParentPtr', 'floatCast', 'floatFromInt',
	'frameAddress', 'hasDecl', 'hasField', 'import', 'intFromBool', 'intFromError', 'intFromFloat',
	'inComptime', 'intCast', 'intFromPtr', 'memcpy', 'memmove', 'memset',
	'wasmMemorySize', 'wasmMemoryGrow', 'mulWithOverflow', 'panic', 'prefetch',
	'popCount', 'ptrCast', 'ptrFromInt', 'reduce', 'rem', 'returnAddress', 'select',
	'setEvalBranchQuota', 'setFloatMode', 'setRuntimeSafety',
	'shlExact', 'shlWithOverflow', 'shrExact', 'shuffle', 'sizeOf', 'splat',
	'src', 'sqrt', 'sin', 'cos', 'tan', 'exp', 'exp2', 'log', 'log2', 'log10',
	'max', 'min', 'mod', 'abs', 'floor', 'ceil', 'trap', 'trunc', 'round',
	'subWithOverflow', 'tagName', 'This', 'truncate',
	'Type', 'typeInfo', 'typeName', 'TypeOf', 'unionInit', 'Vector', 'volatileCast',
	'workGroupId', 'workGroupSize', 'workItemId'
})

-- Special values.
lex:set_word_list(lexer.CONSTANT_BUILTIN, {
	'false', 'true', 'null', 'undefined'
})

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')

lexer.property['scintillua.comment'] = '//'

return lex
