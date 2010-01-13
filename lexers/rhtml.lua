-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- RHTML LPeg lexer

module(..., package.seeall)
local P, S = lpeg.P, lpeg.S

local html = require 'html'
local ruby = require 'ruby'

function LoadTokens()
  html.LoadTokens()
  ruby.LoadTokens()

  local start_token = token('rhtml_tag', '<%' * P('=')^-1)
  local end_token = token('rhtml_tag', '%>')
  ruby.TokenPatterns.whitespace = token('rhtml_whitespace', space^1)
  ruby.TokenPatterns.string = -P('%>') * ruby.TokenPatterns.string
  ruby.TokenPatterns.operator = token('operator', S('!^&*()[]{}-=+/|:;.,?<>~') +
    '%' * -P('>'))
  ruby.TokenPatterns.any_char = token('rhtml_default', any - end_token)
  make_embeddable(ruby, html, start_token, end_token)
  embed_language(html, ruby, true)

  -- TODO: modify HTML, CSS, and JS patterns accordingly

  UseOtherTokens = html.Tokens

  -- Since Ruby is being embedded in the HTML lexer, html.EmbeddedIn is a table
  -- and LexLPeg would recognize it as a multi-language lexer. However, RHTML is
  -- the lexer in use and it has no EmbeddedIn table so it would be recognized
  -- as a single language lexer and styling would be very flaky. Fix this by
  -- adding EmbeddedIn explicitly.
  EmbeddedIn = {}
end

function LoadStyles()
  html.LoadStyles()
  add_style('rhtml_whitespace', style_nothing)
  add_style('rhtml_default', style_nothing)
  add_style('rhtml_tag', style_embedded)
end
