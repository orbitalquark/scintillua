-- Copyright 2006-2014 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Markdown LPeg lexer.

local l = require('lexer')
local token, word_match = l.token, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = {_NAME = 'markdown'}

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Block elements.
local h6 = token('h6', P('######') * l.any^0)
local h5 = token('h5', P('#####') * l.any^0)
local h4 = token('h4', P('####') * l.any^0)
local h3 = token('h3', P('###') * l.any^0)
local h2 = token('h2', P('##') * l.any^0)
local h1 = token('h1', P('#') * l.any^0)
local header = l.starts_line(ws^0 * #P('#') * (h6 + h5 + h4 + h3 + h2 + h1))

local in_blockquote
local blockquote = l.starts_line(ws^0 * token(l.STRING, P('>'))) *
                   P(function(input, index)
                     in_blockquote = true
                     return index
                   end) * token(l.STRING, l.any^0) + P(function(input, index)
                     return in_blockquote and index or nil
                   end) * token(l.STRING, l.any^1)

local blockcode = l.starts_line(token('code', (P(' ')^4 + P('\t')) * -P('<') *
                                              l.any^0))

local hr = l.starts_line(ws^0 * token('hr', #S('*-_') * P(function(input, index)
  local line = input:gsub(' ', '')
  if line:find('[^\r\n*-_]') then return nil end
  if line:find('^%*%*%*') or line:find('^%-%-%-') or line:find('^___') then
    return index
  end
end) * l.any^1))

local blank = l.starts_line(token(l.DEFAULT, l.newline^1 *
                                             P(function(input, index)
                                               in_blockquote = false
                                             end)))

-- Span elements.
local dq_str = token(l.STRING, l.delimited_range('"', false, true))
local sq_str = token(l.STRING, l.delimited_range("'", false, true))
local paren_str = token(l.STRING, l.delimited_range('()'))
local link = token('link', P('!')^-1 * l.delimited_range('[]') *
                           (P('(') * (l.any - S(') \t'))^0 *
                            (l.space^1 *
                             l.delimited_range('"', false, true))^-1 * ')' +
                            l.space^0 * l.delimited_range('[]')) +
                           P('http://') * (l.any - l.space)^1)
local link_label = ws^0 * token('link_label', l.delimited_range('[]') * ':') *
                   ws * token('link_url', (l.any - l.space)^1) *
                   (ws * (dq_str + sq_str + paren_str))^-1

local strong = token('strong', (P('**') * (l.any - '**')^0 * P('**')^-1) +
                               (P('__') * (l.any - '__')^0 * P('__')^-1))
local em = token('em', l.delimited_range('*') + l.delimited_range('_'))
local code = token('code', (P('``') * (l.any - '``')^0 * P('``')^-1) +
                           l.delimited_range('`'))

local escape = token(l.DEFAULT, P('\\') * 1)

local list = l.starts_line(ws^0 * token('list', S('*+-') + R('09') * '.') * ws)

M._rules = {
  {'blank', blank},
  {'header', header},
  {'blockquote', blockquote},
  {'blockcode', blockcode},
  {'hr', hr},
  {'list', list},
  {'whitespace', ws},
  {'link_label', link_label},
  {'escape', escape},
  {'link', link},
  {'strong', strong},
  {'em', em},
  {'code', code},
}

M._LEXBYLINE = true

local font_size = 10
local hstyle = 'fore:$(color.red)'
M._tokenstyles = {
  h6 = hstyle,
  h5 = hstyle..',size:'..(font_size + 1),
  h4 = hstyle..',size:'..(font_size + 2),
  h3 = hstyle..',size:'..(font_size + 3),
  h2 = hstyle..',size:'..(font_size + 4),
  h1 = hstyle..',size:'..(font_size + 5),
  code = l.STYLE_EMBEDDED..',eolfilled',
  hr = 'back:$(color.black),eolfilled',
  link = 'underlined',
  link_url = 'underlined',
  link_label = l.STYLE_LABEL,
  strong = 'bold',
  em = 'italics',
  list = l.STYLE_CONSTANT,
}

-- Embedded HTML.
local html = l.load('html')
local start_rule = l.starts_line(ws^0 * token('tag', P('<')))
local end_rule = token(l.WHITESPACE, P('\n'))
l.embed_lexer(M, html, start_rule, end_rule)

l.property['fold.by.indentation'] = '0' -- revert from CoffeeScript

return M
