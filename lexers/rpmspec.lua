-- Copyright 2022-2023 Matej Cepl mcepl.att.cepl.eu. See LICENSE.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local C, P, R, S = lpeg.C, lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('rpmspec')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, lexer.to_eol('#')))

-- Numbers (including versions)
lex:add_rule('number', token(lexer.NUMBER, lexer.number + S('.+~')))

-- Operators
lex:add_rule('operator', token(lexer.OPERATOR, S('&<>=|')))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.range('"')))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match({
    'Prereq', 'Summary', 'Name', 'Version', 'Packager',
    'Requires', 'Recommends', 'Suggests', 'Supplements',
    'Enhances', 'Icon', 'URL', 'Prefix', 'Packager', 'Group',
    'License', 'Release', 'BuildRoot', 'Distribution', 'Vendor',
    'Provides', 'ExclusiveArch', 'ExcludeArch', 'ExclusiveOS',
    'Obsoletes', 'BuildArch', 'BuildArchitectures', 'BuildRequires',
    'BuildConflicts', 'BuildPreReq', 'Conflicts', 'AutoRequires',
    'AutoReq', 'AutoReqProv', 'AutoProv', 'Epoch'
}) + (P('Patch') + P('Source')) * R('09')^0))

-- Macros
lex:add_rule('command', token(lexer.FUNCTION, S('%$')^1 * S('{')^0 * lexer.word * S('}')^0 ))

-- Constants
lex:add_rule('constant', token(lexer.CONSTANT, word_match({
    'rhel', 'fedora', 'suse_version', 'sle_version', 'x86_64'
})))

lexer.property['scintillua.comment'] = '#'

return lex
