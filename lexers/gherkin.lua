-- Copyright 2015-2022 Jason Schindler. See LICENSE.
-- Gherkin (https://github.com/cucumber/cucumber/wiki/Gherkin) LPeg lexer.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(..., {fold_by_indentation = true})

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- Strings.
local doc_str = lexer.range('"""')
local dq_str = lexer.range('"')
lex:add_rule('string', lex:tag(lexer.STRING, doc_str + dq_str))

-- Comments.
lex:add_rule('comment', lex:tag(lexer.COMMENT, lexer.to_eol('#')))

-- Tags.
lex:add_rule('tag', lex:tag(lexer.LABEL, '@' * lexer.word^0))

-- Placeholders.
lex:add_rule('placeholder', lex:tag(lexer.VARIABLE, lexer.range('<', '>', false, false, true)))

-- Examples.
lex:add_rule('example', lex:tag(lexer.DEFAULT, lexer.to_eol('|')))

-- Word lists.
lex:set_word_list(lexer.KEYWORD, {
  'And', 'Background', 'But', 'Examples', 'Feature', 'Given', 'Outline', 'Scenario', 'Scenarios',
  'Then', 'When'
})

lexer.property['scintillua.comment'] = '#'

return lex
