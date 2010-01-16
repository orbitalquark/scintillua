-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- PHP LPeg lexer

module(..., package.seeall)
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

local ws = token('php_whitespace', space^1)

-- comments
local line_comment = (P('//') + '#') * nonnewline^0
local block_comment = '/*' * (any - '*/')^0 * P('*/')^-1
local comment = token('comment', block_comment + line_comment)

-- strings
local sq_str = delimited_range("'", '\\', true)
local dq_str = delimited_range('"', '\\', true)
local bt_str = delimited_range('`', '\\', true)
local heredoc = '<<<' * P(function(input, index)
  local _, e, delimiter = input:find('([%a_][%w_]*)[\n\r\f]+', index)
  if delimiter then
    local _, e = input:find('[\n\r\f]+'..delimiter, e)
    return e and e + 1
  end
end)
local string = token('string', sq_str + dq_str + bt_str + heredoc)
-- TODO: interpolated code

-- numbers
local number = token('number', float + integer)

-- keywords
local keyword = word_match(word_list{
  'and', 'array', 'as', 'bool', 'boolean', 'break', 'case',
  'cfunction', 'class', 'const', 'continue', 'declare', 'default',
  'die', 'directory', 'do', 'double', 'echo', 'else', 'elseif',
  'empty', 'enddeclare', 'endfor', 'endforeach', 'endif',
  'endswitch', 'endwhile', 'eval', 'exit', 'extends', 'false',
  'float', 'for', 'foreach', 'function', 'global', 'if', 'include',
  'include_once', 'int', 'integer', 'isset', 'list', 'new', 'null',
  'object', 'old_function', 'or', 'parent', 'print', 'real',
  'require', 'require_once', 'resource', 'return', 'static',
  'stdclass', 'string', 'switch', 'true', 'unset', 'use', 'var',
  'while', 'xor', '__class__', '__file__', '__function__',
  '__line__', '__sleep', '__wakeup'
})
keyword = token('keyword', keyword)

-- variables
local word = (alpha + '_' + R('\127\255')) * (alnum + '_' + R('\127\255'))^0
local variable = token('variable', '$' * word)

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('!@%^*&()-+=|/.,;:<>[]{}') + '?' * -P('>'))

local html = require 'hypertext'

function LoadTokens()
  html.LoadTokens()
  local php = php
  add_token(php, 'php_whitespace', ws)
  add_token(php, 'keyword', keyword)
  add_token(php, 'identifier', identifier)
  add_token(php, 'string', string)
  add_token(php, 'variable', variable)
  add_token(php, 'comment', comment)
  add_token(php, 'number', number)
  add_token(php, 'operator', operator)
  add_token(php, 'any_char', token('php_default', any - '?>'))

  -- embedding PHP in HTML
  local start_token = token('php_tag', '<?' * ('php' * space)^-1)
  local end_token = token('php_tag', '?>')
  make_embeddable(php, html, start_token, end_token)
  embed_language(html, php, true)

  -- modify various HTML patterns to accomodate PHP embedding
  local ephp = start_token * php.Token^0 * end_token^-1
  -- strings
  local sq_str = delimited_range_with_embedded("'", '\\', 'string', ephp)
  local dq_str = delimited_range_with_embedded('"', '\\', 'string', ephp)
  local string = sq_str + dq_str
  html.TokenPatterns.string = string
  -- tags
  local ht = html.TokenPatterns
  local attributes = P{ ht.attribute * (ws^0 * ht.equals * ws^0 * (ephp + string + ht.number))^-1 * (ws * V(1))^0 }
  local tag = ht.tag_start * (ws^0 * (attributes + ephp))^0 * ws^0 * ht.tag_end
  html.TokenPatterns.tag = tag
  rebuild_token(html)
  rebuild_tokens(html)

  -- TODO: modify CSS and JS patterns accordingly

  UseOtherTokens = html.Tokens
end

function LoadStyles()
  html.LoadStyles()
  add_style('php_whitespace', style_nothing)
  add_style('php_default', style_nothing)
  add_style('php_tag', style_embedded)
  add_style('variable', style_variable)
end
