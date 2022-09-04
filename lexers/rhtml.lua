-- Copyright 2006-2022 Mitchell. See LICENSE.
-- RHTML LPeg lexer.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(..., {inherit = lexer.load('html')})

-- Embedded Ruby.
local ruby = lexer.load('rails')
local ruby_start_rule = lex:tag(lexer.TAG .. '.rhtml', '<%' * P('=')^-1)
local ruby_end_rule = lex:tag(lexer.TAG .. '.rhtml', '%>')
lex:embed(ruby, ruby_start_rule, ruby_end_rule)

-- Fold points.
lex:add_fold_point(lexer.TAG .. '.rhtml', '<%', '%>')

lexer.property['scintillua.comment'] = '<!--|-->'

return lex
