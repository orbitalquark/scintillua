-- Copyright 2006-2017 Mitchell mitchell.att.foicica.com. See LICENSE.
-- C LPeg lexer.

local l = require('lexer')
local token, word_match = l.token, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = {_NAME = 'ansi_c'}

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local line_comment = '//' * l.nonnewline_esc^0
local block_comment = '/*' * (l.any - '*/')^0 * P('*/')^-1 +
                      l.starts_line('#if') * S(' \t')^0 * '0' * l.space *
                      (l.any - l.starts_line('#endif'))^0 *
                      (l.starts_line('#endif'))^-1
local comment = token(l.COMMENT, line_comment + block_comment)

-- Strings.
local sq_str = P('L')^-1 * l.delimited_range("'", true)
local dq_str = P('L')^-1 * l.delimited_range('"', true)
local string = token(l.STRING, sq_str + dq_str)

-- Numbers.
local number = token(l.NUMBER, l.float + l.integer)

-- Preprocessor.
local preproc_word = word_match{
  'define', 'elif', 'else', 'endif', 'error', 'if', 'ifdef', 'ifndef', 'line',
  'pragma', 'undef', 'warning'
}
local preproc = #l.starts_line('#') *
                (token(l.PREPROCESSOR, '#' * S('\t ')^0 * preproc_word) +
                 token(l.PREPROCESSOR, '#' * S('\t ')^0 * 'include') *
                 (token(l.WHITESPACE, S('\t ')^1) *
                  token(l.STRING, l.delimited_range('<>', true, true)))^-1)

-- Keywords.
local keyword = token(l.KEYWORD, word_match{
  'auto', 'break', 'case', 'const', 'continue', 'default', 'do', 'else',
  'extern', 'for', 'goto', 'if', 'inline', 'register', 'restrict', 'return',
  'sizeof', 'static', 'switch', 'typedef', 'volatile', 'while',
  -- C11.
  '_Alignas', '_Alignof', '_Atomic', '_Generic', '_Noreturn', '_Static_assert',
  '_Thread_local',
})

-- Types.
local type = token(l.TYPE, word_match{
  'char', 'double', 'enum', 'float', 'int', 'long', 'short', 'signed', 'struct',
  'union', 'unsigned', 'void', '_Bool', '_Complex', '_Imaginary',
  -- Stdlib types.
  'ptrdiff_t', 'size_t', 'max_align_t', 'wchar_t',
  'intptr_t', 'uintptr_t', 'intmax_t', 'uintmax_t'
} + P('u')^-1 * P('int') * (P('_least') + P('_fast'))^-1 * R('09')^1 * P('_t'))

-- Constants.
local constant = token(l.CONSTANT, word_match{
  'NULL',
  -- Preprocessor.
  '__DATE__', '__FILE__', '__LINE__', '__TIME__', '__func__',
  -- errno.h.
  'E2BIG', 'EACCES', 'EADDRINUSE', 'EADDRNOTAVAIL', 'EAFNOSUPPORT',
  'EAGAIN', 'EALREADY', 'EBADF', 'EBADMSG', 'EBUSY', 'ECANCELED', 'ECHILD',
  'ECONNABORTED', 'ECONNREFUSED', 'ECONNRESET', 'EDEADLK', 'EDESTADDRREQ',
  'EDOM', 'EDQUOT', 'EEXIST', 'EFAULT', 'EFBIG', 'EHOSTUNREACH', 'EIDRM',
  'EILSEQ', 'EINPROGRESS', 'EINTR', 'EINVAL', 'EIO', 'EISCONN', 'EISDIR',
  'ELOOP', 'EMFILE', 'EMLINK', 'EMSGSIZE', 'EMULTIHOP', 'ENAMETOOLONG',
  'ENETDOWN', 'ENETRESET', 'ENETUNREACH', 'ENFILE', 'ENOBUFS', 'ENODATA',
  'ENODEV', 'ENOENT', 'ENOEXEC', 'ENOLCK', 'ENOLINK', 'ENOMEM',
  'ENOMSG', 'ENOPROTOOPT', 'ENOSPC', 'ENOSR', 'ENOSTR', 'ENOSYS',
  'ENOTCONN', 'ENOTDIR', 'ENOTEMPTY', 'ENOTRECOVERABLE', 'ENOTSOCK',
  'ENOTSUP', 'ENOTTY', 'ENXIO', 'EOPNOTSUPP', 'EOVERFLOW', 'EOWNERDEAD',
  'EPERM', 'EPIPE', 'EPROTO', 'EPROTONOSUPPORT', 'EPROTOTYPE', 'ERANGE',
  'EROFS', 'ESPIPE', 'ESRCH', 'ESTALE', 'ETIME', 'ETIMEDOUT', 'ETXTBSY',
  'EWOULDBLOCK', 'EXDEV',
})

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

-- Operators.
local operator = token(l.OPERATOR, S('+-/*%<>~!=^&|?~:;,.()[]{}'))

M._rules = {
  {'whitespace', ws},
  {'keyword', keyword},
  {'type', type},
  {'constant', constant},
  {'identifier', identifier},
  {'string', string},
  {'comment', comment},
  {'number', number},
  {'preproc', preproc},
  {'operator', operator},
}

M._foldsymbols = {
  _patterns = {'#?%l+', '[{}]', '/%*', '%*/', '//'},
  [l.PREPROCESSOR] = {['if'] = 1, ifdef = 1, ifndef = 1, endif = -1},
  [l.OPERATOR] = {['{'] = 1, ['}'] = -1},
  [l.COMMENT] = {
    ['/*'] = 1, ['*/'] = -1, ['//'] = l.fold_line_comments('//'),
    ['#if'] = 1, ['#endif'] = -1
  }
}

return M
