-- Copyright 2006-2025 Mitchell. See LICENSE.
-- C3 LPeg lexer.

local lexer = lexer
local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- Types.
lex:add_rule('type', lex:tag(lexer.TYPE, lex:word_match(lexer.TYPE)))

-- Functions.
local builtin_func = -(B('.') + B('->')) *
	lex:tag(lexer.FUNCTION_BUILTIN, lex:word_match(lexer.FUNCTION_BUILTIN))
local func = lex:tag(lexer.FUNCTION, lexer.word)
local method = (B('.') + B('->')) * lex:tag(lexer.FUNCTION_METHOD, lexer.word)
lex:add_rule('function', (builtin_func + method + func) * #(lexer.space^0 * '('))

-- Constants.
lex:add_rule('constants', lex:tag(lexer.CONSTANT_BUILTIN,
	-(B('.') + B('->')) * lex:word_match(lexer.CONSTANT_BUILTIN)))

-- Labels.
lex:add_rule('label', lex:tag(lexer.LABEL, lexer.starts_line(lexer.word * ':')))

-- Strings.
local sq_str = lexer.range("'", true)
local dq_str = lexer.range('"', true)
lex:add_rule('string', lex:tag(lexer.STRING, P('L')^-1 * (sq_str + dq_str)))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))

-- Comments.
local line_comment = lexer.to_eol('//', true) + lexer.to_eol('#!', true)
local ws = S(' \t')^0
local block_comment = lexer.range('/*', '*/') + lexer.range('<*', '*>') 
    + lexer.range('$if' * ws * '0' * lexer.space, '$endif')
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))

-- Numbers. (no changes here!)
local integer = lexer.integer * lexer.word_match('u l ll ul ull lu llu', true)^-1
local float = lexer.float * lexer.word_match('f l df dd dl i j', true)^-1
lex:add_rule('number', lex:tag(lexer.NUMBER, float + integer))

-- Preprocessor.
local include = lex:tag(lexer.PREPROCESSOR, '$' * ws * 'include') *
	(lex:get_rule('whitespace') * lex:tag(lexer.STRING, lexer.range('<', '>', true)))^-1
local preproc = lex:tag(lexer.PREPROCESSOR, '$' * ws * lex:word_match(lexer.PREPROCESSOR))
lex:add_rule('preprocessor', include + preproc)

-- Attributes.
local standard_attr = lex:word_match(lexer.ATTRIBUTE)
local non_standard_attr = lexer.word * '::' * lexer.word
local attr_args = lexer.range('(', ')')
local attr = (non_standard_attr + standard_attr) * attr_args^-1
lex:add_rule('attribute', lex:tag(lexer.ATTRIBUTE, '[[' * attr * (ws * ',' * ws * attr)^0 * ']]'))

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('+-/*%<>~!=^&|?~:;,.()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.PREPROCESSOR, '$if', '$endif')
lex:add_fold_point(lexer.PREPROCESSOR, '$for', '$endfor')
lex:add_fold_point(lexer.PREPROCESSOR, '$foreach', '$endforeach')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '<*', '*>')

-- Word lists.
lex:set_word_list(lexer.KEYWORD, {
    'inline', 'alias', 'default', 'do', 'else', 'var', 'while', 'nextcase', 'switch', 'fn', 'local', 'attrdef', 'if', 'foreach_r', 'extern', 'foreach', 'import', 'macro', 'for', 'case', 'catch', 'continue', 'try', 'break', 'typedef', 'return', 'const', 'module', 'typeid', 'defer', 'assert', 'asm', 'static', 'tlocal', -- Base keywords
    'alignof', 'associated', 'elements', 'extnameof', 'inf', 'inner', 'kindof', 'len', 'max', 'membersof', 'methodsof', 'min', 'nan', 'nameof', 'names', 'paramsof', 'parentof', 'qnameof','returns', 'sizeof', 'typeid', 'values', -- 0.7.x reflection syntax
})

lex:set_word_list(lexer.TYPE, {
    'isz', 'iptr', 'uint128', 'double', 'float', 'fault', 'struct', 'int128', 'ulong', 'uptr', 'true', 'fn', 'void', 'union', 'float16', 'bitstruct', 'false', 'enum', 'bool', 'ichar', 'int', 'float128', 'any', 'char', 'null', 'usz', 'long', 'short', 'ushort', 'uint',
})

-- No edits here since some are prob shared between both languages
-- TODO: clean this up, probably
lex:set_word_list(lexer.FUNCTION_BUILTIN, {
    'print', 'printf', 'printn', 'printfn', -- io::print*
    'panic', 'panicf', -- builtion::panic*
	'assert', -- assert.h
	-- complex.h.
	'CMPLX', 'creal', 'cimag', 'cabs', 'carg', 'conj', 'cproj',
	-- C99
	'cexp', 'cpow', 'csin', 'ccos', 'ctan', 'casin', 'cacos', 'catan', 'csinh', 'ccosh', 'ctanh',
	'casinh', 'cacosh', 'catanh',
	-- ctype.h.
	'isalnum', 'isalpha', 'islower', 'isupper', 'isdigit', 'isxdigit', 'iscntrl', 'isgraph',
	'isspace', 'isprint', 'ispunct', 'tolower', 'toupper', --
	'isblank', -- C99
	-- inttypes.h.
	'INT8_C', 'INT16_C', 'INT32_C', 'INT64_C', 'INTMAX_C', 'UINT8_C', 'UINT16_C', 'UINT32_C',
	'UINT64_C', 'UINTMAX_C', --
	'setlocale', 'localeconv', -- locale.h
	-- math.h.
	'abs', 'div', 'fabs', 'fmod', 'exp', 'log', 'log10', 'pow', 'sqrt', 'sin', 'cos', 'tan', 'asin',
	'acos', 'atan', 'atan2', 'sinh', 'cosh', 'tanh', 'ceil', 'floor', 'frexp', 'ldexp', 'modf',
	-- C99.
	'remainder', 'remquo', 'fma', 'fmax', 'fmin', 'fdim', 'nan', 'exp2', 'expm1', 'log2', 'log1p',
	'cbrt', 'hypot', 'asinh', 'acosh', 'atanh', 'erf', 'erfc', 'tgamma', 'lgamma', 'trunc', 'round',
	'nearbyint', 'rint', 'scalbn', 'ilogb', 'logb', 'nextafter', 'nexttoward', 'copysign', 'isfinite',
	'isinf', 'isnan', 'isnormal', 'signbit', 'isgreater', 'isgreaterequal', 'isless', 'islessequal',
	'islessgreater', 'isunordered', --
	'strtoimax', 'strtoumax', -- inttypes.h C99
	'signal', 'raise', -- signal.h
	'setjmp', 'longjmp', -- setjmp.h
	'va_start', 'va_arg', 'va_end', -- stdarg.h
	-- stdio.h.
	'fopen', 'freopen', 'fclose', 'fflush', 'setbuf', 'setvbuf', 'fwide', 'fread', 'fwrite', 'fgetc',
	'getc', 'fgets', 'fputc', 'putc', 'getchar', 'gets', 'putchar', 'puts', 'ungetc', 'scanf',
	'fscanf', 'sscanf', 'printf', 'fprintf', 'sprintf', 'vprintf', 'vfprintf', 'vsprintf', 'ftell',
	'fgetpos', 'fseek', 'fsetpos', 'rewind', 'clearerr', 'feof', 'ferror', 'perror', 'remove',
	'rename', 'tmpfile', 'tmpnam',
	-- stdlib.h.
	'abort', 'exit', 'atexit', 'system', 'getenv', 'malloc', 'calloc', 'realloc', 'free', 'atof',
	'atoi', 'atol', 'strtol', 'strtoul', 'strtod', 'mblen', 'mbsinit', 'mbrlen', 'qsort', 'bsearch',
	'rand', 'srand', --
	'quick_exit', '_Exit', 'at_quick_exit', 'aligned_alloc', -- C11
	-- string.h.
	'strcpy', 'strncpy', 'strcat', 'strncat', 'strxfrm', 'strlen', 'strcmp', 'strncmp', 'strcoll',
	'strchr', 'strrchr', 'strspn', 'strcspn', 'strpbrk', 'strstr', 'strtok', 'memchr', 'memcmp',
	'memset', 'memcpy', 'memmove', 'strerror',
	-- time.h.
	'difftime', 'time', 'clock', 'asctime', 'ctime', 'gmtime', 'localtime', 'mktime', --
	'timespec_get' -- C11
})

lex:set_word_list(lexer.CONSTANT_BUILTIN, {
    '$$BENCHMARK_FNS', '$$FILEPATH', '$$BENCHMARK_NAMES', '$$LINE_RAW', '$$MODULE', '$$TEST_FNS', '$$TEST_NAMES', '$$TIME', '$$LINE', '$$FUNC', '$$FUNCTION', '$$DATE', '$$FILE',
})

lex:set_word_list(lexer.PREPROCESSOR, {
    '$evaltype', '$qnameof', '$sizeof', '$vasplat', '$alignof', '$for', '$echo', '$vatype', '$if', '$include', '$endforeach', '$exec', '$else', '$switch', '$error', '$extnameof', '$nameof', '$vacount', '$vaconst', '$vaarg', '$offsetof', '$endfor', '$embed', '$default', '$defined', '$endif', '$endswitch', '$assert', '$stringify', '$foreach', '$typefrom', '$typeof', '$eval', '$case', '$vaexpr',
})

lex:set_word_list(lexer.ATTRIBUTE, {
    '@builtin', '@cdecl', '@maydiscard', '@reflect', '@obfuscate', '@align', '@priority', '@weak', '@bigendian', '@noinline', '@noreturn', '@winmain', '@nostrip', '@test', '@operator', '@overlap', '@deprecated', '@interface', '@littleendian', '@packed', '@pure', '@local', '@benchmark', '@mustinit', '@naked', '@private', '@public', '@dynamic', '@export', '@section', '@stdcall', '@inline', '@cname', '@nodiscard', '@unused', '@noinit', '@extname', '@wasm', '@used', '@veccall', -- In language reference
    '@param', '@ensure', '@require', -- Specifically for function doc comments/contracts
})

lexer.property['scintillua.comment'] = '//'

return lex
