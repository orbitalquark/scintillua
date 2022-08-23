-- Copyright 2006-2022 Mitchell. See LICENSE.
-- C LPeg lexer.

local lexer = lexer
local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new(...)

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:get_word_list(lexer.KEYWORD)))

-- Types.
local basic_type = lex:get_word_list(lexer.TYPE)
local fixed_width_type = P('u')^-1 * 'int' * (P('_least') + '_fast')^-1 * lexer.digit^1 * '_t' *
  -(lexer.alnum + '_')
lex:add_rule('type', lex:tag(lexer.TYPE, basic_type + fixed_width_type))

-- Functions.
local builtin_func = -(B('.') + B('->')) *
  lex:tag(lexer.FUNCTION_BUILTIN, lex:get_word_list(lexer.FUNCTION_BUILTIN))
local func = lex:tag(lexer.FUNCTION, lexer.word)
local method = (B('.') + B('->')) * lex:tag(lexer.FUNCTION_METHOD, lexer.word)
lex:add_rule('function', (builtin_func + method + func) * #(lexer.space^0 * '('))

-- Constants.
local constant = lex:get_word_list(lexer.CONSTANT_BUILTIN)
local fixed_width_constant = P('U')^-1 * 'INT' *
  ((P('_LEAST') + '_FAST')^-1 * lexer.digit^1 + 'PTR' + 'MAX') * (P('_MIN') + '_MAX') *
  -(lexer.alnum + '_')
lex:add_rule('constants', lex:tag(lexer.CONSTANT_BUILTIN, constant + fixed_width_constant))

-- Labels.
lex:add_rule('label', lex:tag(lexer.LABEL, lexer.starts_line(lexer.word * ':')))

-- Strings.
local sq_str = lexer.range("'", true)
local dq_str = lexer.range('"', true)
lex:add_rule('string', lex:tag(lexer.STRING, P('L')^-1 * (sq_str + dq_str)))

-- Identifiers.
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, lexer.word))

-- Comments.
local line_comment = lexer.to_eol('//', true)
local block_comment = lexer.range('/*', '*/') +
  lexer.range('#if' * S(' \t')^0 * '0' * lexer.space, '#endif')
lex:add_rule('comment', lex:tag(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
local integer = lexer.integer * lexer.word_match('u l ll ul ull lu llu', true)^-1
local float = lexer.float * P('f')^-1
lex:add_rule('number', lex:tag(lexer.NUMBER, float + integer))

-- Preprocessor.
local include = lex:tag(lexer.PREPROCESSOR, '#' * S('\t ')^0 * 'include') *
  (lex:get_rule('whitespace') * lex:tag(lexer.STRING, lexer.range('<', '>', true)))^-1
local preproc =
  lex:tag(lexer.PREPROCESSOR, '#' * S('\t ')^0 * lex:get_word_list(lexer.PREPROCESSOR))
lex:add_rule('preprocessor', include + preproc)

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('+-/*%<>~!=^&|?~:;,.()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.PREPROCESSOR, '#if', '#endif')
lex:add_fold_point(lexer.PREPROCESSOR, '#ifdef', '#endif')
lex:add_fold_point(lexer.PREPROCESSOR, '#ifndef', '#endif')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, lexer.fold_consecutive_lines('//'))

-- Word lists.
lex:set_word_list(lexer.KEYWORD, {
  'auto', 'break', 'case', 'const', 'continue', 'default', 'do', 'else', 'enum', 'extern', 'for',
  'goto', 'if', 'inline', 'register', 'restrict', 'return', 'sizeof', 'static', 'switch', 'typedef',
  'volatile', 'while',
  -- C99.
  'false', 'true',
  -- C11.
  '_Alignas', '_Alignof', '_Atomic', '_Generic', '_Noreturn', '_Static_assert', '_Thread_local',
  -- Compiler.
  'asm', '__asm', '__asm__', '__restrict__', '__inline', '__inline__', '__attribute__', '__declspec'
})

lex:set_word_list(lexer.TYPE, {
  'bool', 'char', 'double', 'float', 'int', 'long', 'short', 'signed', 'struct', 'union',
  'unsigned', 'void', --
  'bool', 'complex', 'imaginary', '_Bool', '_Complex', '_Imaginary', -- C99
  'max_align_t', -- C11
  'va_list', -- stdarg.h
  'size_t', 'ptrdiff_t', -- stddef.h
  'intptr_t', 'uintptr_t', 'intmax_t', 'uintmax_t', 'wchar_t', -- stdint.h
  'FILE', 'fpos_t', -- stdio.h
  'div_t', 'ldiv_t', -- stdlib.h
  'lconv', -- locale.h
  'tm', 'time_t', 'clock_t' -- time.h
})

lex:set_word_list(lexer.FUNCTION_BUILTIN, {
  -- assert.h.
  'assert',
  -- stdarg.h.
  'va_start', 'va_arg', 'va_end',
  -- ctype.h.
  'isalnum', 'isalpha', 'islower', 'isupper', 'isdigit', 'isxdigit', 'iscntrl', 'isgraph',
  'isspace', 'isprint', 'ispunct', 'tolower', 'toupper', --
  'isblank', -- C99
  -- stdlib.h.
  'abort', 'exit', 'atexit', 'system', 'getenv', 'malloc', 'calloc', 'realloc', 'free', 'atof',
  'atoi', 'atol', 'strtol', 'strtoul', 'strtod', 'mblen', 'mbsinit', 'mbrlen', 'qsort', 'bsearch',
  'abs', 'labs', 'div', 'ldiv', 'fabs', 'fmod', 'exp', 'log', 'log10', 'pow', 'sqrt', 'sin', 'cos',
  'tan', 'asin', 'acos', 'atan', 'atan2', 'sinh', 'cosh', 'tanh', 'ceil', 'floor', 'frexp', 'ldexp',
  'modf', 'rand', 'srand',
  -- inttypes.h C99.
  'strtoimax', 'strtoumax',
  -- locale.h.
  'setlocale', 'localeconv',
  -- signal.h.
  'signal', 'raise',
  -- setjmp.h.
  'setjmp', 'longjmp',
  -- stdio.h.
  'fopen', 'freopen', 'fclose', 'fflush', 'setbuf', 'setvbuf', 'fwide', 'fread', 'fwrite', 'fgetc',
  'getc', 'fgets', 'fputc', 'putc', 'getchar', 'gets', 'putchar', 'puts', 'ungetc', 'scanf',
  'fscanf', 'sscanf', 'printf', 'fprintf', 'sprintf', 'vprintf', 'vfprintf', 'vsprintf', 'clearerr',
  'feof', 'ferror', 'perror', 'remove', 'rename', 'tmpfile', 'tmpnam',
  -- string.h.
  'strcpy', 'strncpy', 'strcat', 'strncat', 'strxfrm', 'strlen', 'strcmp', 'strncmp', 'strcoll',
  'strchr', 'strrchr', 'strspn', 'strcspn', 'strpbrk', 'strstr', 'strtok', 'memchr', 'memcmp',
  'memset', 'memcpy', 'memmove', 'strerror',
  -- time.h.
  'difftime', 'time', 'clock', 'asctime', 'ctime', 'wcsftime', 'gmtime', 'localtime', 'mktime'
})

lex:set_word_list(lexer.CONSTANT_BUILTIN, {
  'true', 'false', 'NULL',
  -- Preprocessor.
  '__DATE__', '__FILE__', '__LINE__', '__TIME__', '__func__',
  -- errno.h.
  'errno', --
  'E2BIG', 'EACCES', 'EADDRINUSE', 'EADDRNOTAVAIL', 'EAFNOSUPPORT', 'EAGAIN', 'EALREADY', 'EBADF',
  'EBADMSG', 'EBUSY', 'ECANCELED', 'ECHILD', 'ECONNABORTED', 'ECONNREFUSED', 'ECONNRESET',
  'EDEADLK', 'EDESTADDRREQ', 'EDOM', 'EDQUOT', 'EEXIST', 'EFAULT', 'EFBIG', 'EHOSTUNREACH', 'EIDRM',
  'EILSEQ', 'EINPROGRESS', 'EINTR', 'EINVAL', 'EIO', 'EISCONN', 'EISDIR', 'ELOOP', 'EMFILE',
  'EMLINK', 'EMSGSIZE', 'EMULTIHOP', 'ENAMETOOLONG', 'ENETDOWN', 'ENETRESET', 'ENETUNREACH',
  'ENFILE', 'ENOBUFS', 'ENODATA', 'ENODEV', 'ENOENT', 'ENOEXEC', 'ENOLCK', 'ENOLINK', 'ENOMEM',
  'ENOMSG', 'ENOPROTOOPT', 'ENOSPC', 'ENOSR', 'ENOSTR', 'ENOSYS', 'ENOTCONN', 'ENOTDIR',
  'ENOTEMPTY', 'ENOTRECOVERABLE', 'ENOTSOCK', 'ENOTSUP', 'ENOTTY', 'ENXIO', 'EOPNOTSUPP',
  'EOVERFLOW', 'EOWNERDEAD', 'EPERM', 'EPIPE', 'EPROTO', 'EPROTONOSUPPORT', 'EPROTOTYPE', 'ERANGE',
  'EROFS', 'ESPIPE', 'ESRCH', 'ESTALE', 'ETIME', 'ETIMEDOUT', 'ETXTBSY', 'EWOULDBLOCK', 'EXDEV',
  -- float.h.
  'FLT_MIN', 'DBL_MIN', 'LDBL_MIN', 'FLT_MAX', 'DBL_MAX', 'LDBL_MAX',
  -- limits.h.
  'CHAR_BIT', 'MB_LEN_MAX', 'CHAR_MIN', 'CHAR_MAX', 'SCHAR_MIN', 'SHRT_MIN', 'INT_MIN', 'LONG_MIN',
  'SCHAR_MAX', 'SHRT_MAX', 'INT_MAX', 'LONG_MAX', 'UCHAR_MAX', 'USHRT_MAX', 'UINT_MAX', 'ULONG_MAX',
  -- locale.h.
  'LC_ALL', 'LC_COLLATE', 'LC_CTYPE', 'LC_MONETARY', 'LC_NUMERIC', 'LC_TIME',
  -- math.h.
  'HUGE_VAL', --
  'INFINITY', 'NAN', -- C99
  -- stdint.h C99.
  'LLONG_MIN', 'ULLONG_MAX', 'PTRDIFF_MIN', 'PTRDIFF_MAX', 'SIZE_MAX', 'SIG_ATOMIC_MIN',
  'SIG_ATOMIC_MAX', 'WINT_MIN', 'WINT_MAX', 'WCHAR_MIN', 'WCHAR_MAX',
  -- stdlib.h.
  'EXIT_SUCCESS', 'EXIT_FAILURE', 'RAND_MAX',
  -- signal.h.
  'SIG_DFL', 'SIG_IGN', 'SIG_ERR', 'SIGABRT', 'SIGFPE', 'SIGILL', 'SIGINT', 'SIGSEGV', 'SIGTERM',
  -- stdio.h
  'stdin', 'stdout', 'stderr', 'EOF', 'FOPEN_MAX', 'FILENAME_MAX', 'BUFSIZ', '_IOFBF', '_IOLBF',
  '_IONBF', 'SEEK_SET', 'SEEK_CUR', 'SEEK_END', 'TMP_MAX',
  -- time.h.
  'CLOCKS_PER_SEC'
})

lex:set_word_list(lexer.PREPROCESSOR, {
  'define', 'defined', 'elif', 'else', 'endif', 'error', 'if', 'ifdef', 'ifndef', 'line', 'pragma',
  'undef'
})

return lex
