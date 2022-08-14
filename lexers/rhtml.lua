-- Copyright 2006-2022 Mitchell. See LICENSE.
-- RHTML LPeg lexer.

local lexer = require('lexer')
local word_match = lexer.word_match
local P, S = lpeg.P, lpeg.S

local lex = lexer.new('rhtml', {inherit = lexer.load('html')})

-- Embedded Ruby.
local ruby = lexer.load('rails')
local ruby_start_rule = lex:tag('rhtml_tag', '<%' * P('=')^-1)
local ruby_end_rule = lex:tag('rhtml_tag', '%>')
lex:embed(ruby, ruby_start_rule, ruby_end_rule)

-- Fold points.
lex:add_fold_point('rhtml_tag', '<%', '%>')

return lex
