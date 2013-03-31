-- Copyright 2006-2013 Robert Gieseke. See LICENSE.
-- Literate CoffeeScript LPeg lexer.
-- http://coffeescript.org/#literate

local l = lexer
local token = l.token
local P = lpeg.P

local M = {_NAME = 'litcoffee'}

-- Embedded in Markdown.
local markdown = l.load('markdown')
M._lexer = markdown

-- Embedded CoffeeScript.
local coffeescript = l.load('coffeescript')
local coffee_start_rule = token(l.style_embedded, (P(' ')^4 + P('\t')))
local coffee_end_rule = token(l.style_embedded, l.newline)
l.embed_lexer(markdown, coffeescript, coffee_start_rule, coffee_end_rule)

return M
