-- Archlinux PKGBUILD LPeg Lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', '#' * nonnewline^0)

-- strings
local sq_str = delimited_range("'", nil, true)
local dq_str = delimited_range('"', '\\', true)
local ex_str = delimited_range('`', '\\', true)
local heredoc = '<<' * P(function(input, index)
  local s, e, _, delimiter = input:find('(["\']?)([%a_][%w_]*)%1[\n\r\f;]+', index)
  if s == index and delimiter then
    local _, e = input:find('[\n\r\f]+'..delimiter, e)
    return e and e + 1 or #input + 1
  end
end)
local string = token('string', sq_str + dq_str + ex_str + heredoc)

-- numbers
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
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
local func = token('function', word_match(word_list{
  'build'
}))

local constant = token('constant', word_match(word_list{
  'pkgname', 'pkgver', 'pkgrel', 'pkgdesc', 'arch', 'url',
  'license', 'optdepends', 'depends', 'makedepends', 'provides',
  'conflicts', 'replaces', 'install', 'source', 'md5sums',
  'pkgdir', 'srcdir'
}))

-- identifiers
local identifier = token('identifier', word)

-- variables
local variable = token('variable', '$' * (S('!#?*@$') +
  delimited_range('()', nil, true, false, '\n') +
  delimited_range('[]', nil, true, false, '\n') +
  delimited_range('{}', nil, true, false, '\n') +
  delimited_range('`', nil, true, false, '\n') +
  digit^1 +
  word))

-- operators
local operator = token('operator', S('=!<>+-/*^~.,:;?()[]{}'))

function LoadTokens()
  add_token(pkgbuild, 'whitespace', ws)
  add_token(pkgbuild, 'comment', comment)
  add_token(pkgbuild, 'string', string)
  add_token(pkgbuild, 'number', number)
  add_token(pkgbuild, 'keyword', keyword)
  add_token(pkgbuild, 'function', func)
  add_token(pkgbuild, 'constant', constant)
  add_token(pkgbuild, 'identifier', identifier)
  add_token(pkgbuild, 'variable', variable)
  add_token(pkgbuild, 'operator', operator)
  add_token(pkgbuild, 'any_char', any_char)
end

