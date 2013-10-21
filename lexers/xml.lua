-- Copyright 2006-2013 Mitchell mitchell.att.foicica.com. See LICENSE.
-- XML LPeg lexer.

local l, token, word_match = lexer, lexer.token, lexer.word_match
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

local M = {_NAME = 'xml'}

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments and CDATA.
local comment = token(l.COMMENT, '<!--' * (l.any - '-->')^0 * P('-->')^-1)
local cdata = token('cdata', '<![CDATA[' * (l.any - ']]>')^0 * P(']]>')^-1)

-- Strings.
local sq_str = l.delimited_range("'", false, true)
local dq_str = l.delimited_range('"', false, true)
local string = token(l.STRING, sq_str + dq_str)

local equals = token(l.OPERATOR, '=')
local number = token(l.NUMBER, l.digit^1 * P('%')^-1)
local alpha = R('az', 'AZ', '\127\255')
local word_char = l.alnum + S('_-:.??')
local identifier = (l.alpha + S('_-:.??')) * word_char^0

-- Tags.
local namespace = token('namespace', identifier)
local element = token('element', identifier) *
                (token(l.OPERATOR, ':') * namespace)^-1
local normal_attr = token('attribute', identifier)
local xmlns_attr = token('attribute', identifier) * token(l.OPERATOR, ':') *
                   namespace
local attribute = xmlns_attr + normal_attr
local attributes = {attribute * ws^0 * equals * ws^0 * (string + number) *
                    (ws * V(1))^0}
local tag_start = token('tag', '<' * P('/')^-1) * element
local tag_end = token('tag', P('/')^-1 * '>')
local tag = tag_start * (ws * attributes)^0 * ws^0 * tag_end

-- Doctypes and other markup tags
local doctype = token('doctype', P('<!DOCTYPE')) * ws *
                token('doctype', identifier) * (ws * identifier)^-1 *
                (1 - P('>'))^0 * token('doctype', '>')

-- Processing instructions
local proc_insn = token('proc_insn', P('<?') * identifier) *
                  (ws * attributes)^0 * ws^0 * token('proc_insn', '?>')

-- Entities.
local entity = token('entity', '&' * word_match{
  'lt', 'gt', 'amp', 'apos', 'quot'
} * ';')

M._rules = {
  {'whitespace', ws},
  {'comment', comment},
  {'cdata', cdata},
  {'doctype', doctype},
  {'proc_insn', proc_insn},
  {'tag', tag},
  {'entity', entity},
}

M._tokenstyles = {
  tag = l.STYLE_KEYWORD,
  element = l.STYLE_KEYWORD,
  namespace = l.STYLE_CLASS,
  attribute = l.STYLE_TYPE,
  cdata = l.STYLE_COMMENT,
  entity = l.STYLE_OPERATOR,
  doctype = l.STYLE_COMMENT,
  proc_insn = l.STYLE_COMMENT,
  --markup = l.STYLE_COMMENT
}

M._foldsymbols = {
  _patterns = {'</?', '/>', '<!%-%-', '%-%->', '<!%[CDATA%[', '%]%]>'},
  tag = {['<'] = 1, ['/>'] = -1, ['</'] = -1},
  [l.COMMENT] = {['<!--'] = 1, ['-->'] = -1},
  cdata = {['<![CDATA['] = 1, [']]>'] = -1}
}

return M
