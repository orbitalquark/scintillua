-- Copyright 2006-2022 Mitchell. See LICENSE.
-- Fennel LPeg lexer.
-- Contributed by Momohime Honda.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, S, B = lpeg.P, lpeg.S, lpeg.B

local lex = lexer.new('fennel', {inherit = lexer.load('lua')})

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:modify_rule('keyword', token(lexer.KEYWORD, word_match[[
  # % * + - -> ->> -?> -?>> . .. / // : < <= = > >= ?. ^ accumulate
  and band bnot bor bxor collect comment do doto each eval-compiler fn
  for global hashfn icollect if import-macros include lambda length
  let local lshift lua macro macrodebug macros match not not=
  or partial pick-args pick-values quote require-macros rshift set
  set-forcibly! tset values var when while with-open ~= λ
]]))

-- To regenerate the above:
-- (table.concat (doto (icollect [k v (pairs (fennel.syntax))]
--                     (if (or v.special? v.macro?) k)) table.sort) " ")

-- Identifiers.
local initial = lexer.alpha + S"|$%&#*+-/<=>?^_λ!"
local subsequent = initial + lexer.digit
local identifier = initial * subsequent^0 * S"#"^-1
lex:modify_rule('identifier', token(lexer.IDENTIFIER, identifier))

-- Strings.
lex:modify_rule('string', token(lexer.STRING, lexer.range('"')))
local kwstring = B(1-subsequent) * P(":") * subsequent^1
lex:add_rule('kwstring', token(lexer.STRING, kwstring))

-- Comments.
lex:modify_rule('comment', token(lexer.COMMENT, lexer.to_eol(';')))

-- Ignore these rules.
lex:modify_rule('label', P(false))
lex:modify_rule('operator', P(false))
lex:modify_rule('longstring', P(false))

return lex
