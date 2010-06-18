-- Archlinux PKGBUILD LPeg Lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local comment = token('comment', '#' * l.nonnewline^0)

-- strings
local sq_str = l.delimited_range("'", nil, true)
local dq_str = l.delimited_range('"', '\\', true)
local ex_str = l.delimited_range('`', '\\', true)
local heredoc = '<<' * P(function(input, index)
  local s, e, _, delimiter =
    input:find('(["\']?)([%a_][%w_]*)%1[\n\r\f;]+', index)
  if s == index and delimiter then
    local _, e = input:find('[\n\r\f]+'..delimiter, e)
    return e and e + 1 or #input + 1
  end
end)
local string = token('string', sq_str + dq_str + ex_str + heredoc)

-- numbers
local number = token('number', l.float + l.integer)

-- keywords
local keyword = token('keyword', word_match({
  'patch', 'cd', 'make', 'patch', 'mkdir', 'cp', 'sed', 'install', 'rm',
  'if', 'then', 'elif', 'else', 'fi', 'case', 'in', 'esac', 'while', 'for',
  'do', 'done', 'continue', 'local', 'return', 'git', 'svn', 'co', 'clone',
  'gconf-merge-schema', 'msg', 'echo', 'ln',
  -- operators
  '-a', '-b', '-c', '-d', '-e', '-f', '-g', '-h', '-k', '-p', '-r', '-s', '-t',
  '-u', '-w', '-x', '-O', '-G', '-L', '-S', '-N', '-nt', '-ot', '-ef', '-o',
  '-z', '-n', '-eq', '-ne', '-lt', '-le', '-gt', '-ge', '-Np', '-i'
}, '-'))

-- functions
local func = token('function', word_match { 'build' })

local constant = token('constant', word_match {
  'pkgname', 'pkgver', 'pkgrel', 'pkgdesc', 'arch', 'url',
  'license', 'optdepends', 'depends', 'makedepends', 'provides',
  'conflicts', 'replaces', 'install', 'source', 'md5sums',
  'pkgdir', 'srcdir'
})

-- identifiers
local identifier = token('identifier', l.word)

-- variables
local variable =
  token('variable', '$' * (S('!#?*@$') +
        l.delimited_range('()', nil, true, false, '\n') +
        l.delimited_range('[]', nil, true, false, '\n') +
        l.delimited_range('{}', nil, true, false, '\n') +
        l.delimited_range('`', nil, true, false, '\n') + l.digit^1 + l.word))

-- operators
local operator = token('operator', S('=!<>+-/*^~.,:;?()[]{}'))

_rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'string', string },
  { 'number', number },
  { 'keyword', keyword },
  { 'function', func },
  { 'constant', constant },
  { 'identifier', identifier },
  { 'variable', variable },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
