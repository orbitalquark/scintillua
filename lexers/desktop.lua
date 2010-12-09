-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Desktop Entry LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token(l.WHITESPACE, l.space^1)

-- comments
local comment = token(l.COMMENT, '#' * l.nonnewline^0)

-- strings
local string = token(l.STRING, l.delimited_range('"', '\\', true))

-- group headers
local group_header = l.starts_line(token(l.STRING,
                                         l.delimited_range('[]', nil, true)))

-- numbers
local number = token(l.NUMBER, (l.float + l.integer))

-- keywords
local keyword = token(l.KEYWORD, word_match { 'true', 'false' })

-- locales
local locale = token(l.CLASS, l.delimited_range('[]', nil, true))

-- keys
local key = token(l.VARIABLE, word_match {
  'Type', 'Version', 'Name', 'GenericName', 'NoDisplay', 'Comment', 'Icon',
  'Hidden', 'OnlyShowIn', 'NotShowIn', 'TryExec', 'Exec', 'Exec', 'Path',
  'Terminal', 'MimeType', 'Categories', 'StartupNotify', 'StartupWMClass', 'URL'
})

-- field codes
local code = l.token(l.CONSTANT, P('%') * S('fFuUdDnNickvm'))

-- identifiers
local identifier = l.token(l.IDENTIFIER, l.alpha * (l.alnum + '-')^0)

-- operators
local operator = token(l.OPERATOR, S('='))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'key', key },
  { 'identifier', identifier },
  { 'group_header', group_header },
  { 'locale', locale },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'code', code },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
