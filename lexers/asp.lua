-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- ASP LPeg lexer

module(..., package.seeall)
local P, S = lpeg.P, lpeg.S

local html = require 'hypertext'
local vb = require 'vb'

function LoadTokens()
  html.LoadTokens()
  vb.LoadTokens()

  local start_token = token('asp_tag', '<%' * P('=')^-1)
  local end_token = token('asp_tag', '%>')
  vb.TokenPatterns.whitespace = token('vb_whitespace', space^1)
  vb.TokenPatterns.string = -P('%>') * vb.TokenPatterns.string
  vb.TokenPatterns.any_char = token('vb_default', any - end_token)
  make_embeddable(vb, html, start_token, end_token)
  embed_language(html, vb, true)

  -- TODO: modify HTML, CSS, and JS patterns accordingly

  UseOtherTokens = html.Tokens
end

function LoadStyles()
  html.LoadStyles()
  add_style('vb_whitespace', style_nothing)
  add_style('vb_default', style_nothing)
  add_style('asp_tag', style_embedded)
end
