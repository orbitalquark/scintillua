-- Copyright 2022 Matej Cepl mcepl.att.cepl.eu, MIT/X11 license

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('rpmspec')

-- Whitespace.
local ws = token(lexer.WHITESPACE, lexer.space^1)
lex:add_rule('whitespace', ws)

-- Comments.
local comment = token(lexer.COMMENT, lexer.to_eol('#'))
lex:add_rule('comment', comment)

-- Strings.
local string = token(lexer.STRING, lexer.delimited_range('"'))
lex:add_rule('string', string)

-- -- Keywords.
-- local keyword = token(lexer.KEYWORD, word_match({
--   ''
-- }, nil, true))
-- lex:add_rule('keyword', keyword)

-- Macros
local command = token(lexer.FUNCTION, '%' * lexer.word)
lex:add_rule('command', command)

-- -- Constants.
-- local constant = token(lexer.CONSTANT, word_match({
-- }, nil, true))
-- lex:add_rule('constant', constant)

-- Identifiers.
local identifier = token(lexer.IDENTIFIER, word_match({
  'Prereq', 'Summary', 'Name', 'Version', 'Packager', 'Requires',
  'Recommends', 'Suggests', 'Supplements', 'Enhances', 'Icon', 'URL',
  'Source', 'Patch', 'Prefix', 'Packager', 'Group', 'License',
  'Release', 'BuildRoot', 'Distribution', 'Vendor', 'Provides',
  'ExclusiveArch', 'ExcludeArch', 'ExclusiveOS', 'Obsoletes',
  'BuildArch', 'BuildArchitectures', 'BuildRequires', 'BuildConflicts',
  'BuildPreReq', 'Conflicts', 'AutoRequires', 'AutoReq', 'AutoReqProv',
  'AutoProv', 'Epoch'
}))
lex:add_rule('identifier', identifier)

return lex
