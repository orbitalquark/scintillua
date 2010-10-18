--------------------------------------------------------------------------------
-- The MIT License
--
-- Copyright (c) 2009 Brian "Sir Alaran" Schott
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--------------------------------------------------------------------------------

-- Based off of lexer code by Mitchell

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token(l.WHITESPACE, l.space^1)

local line_comment = '//' * l.nonnewline_esc^0
local block_comment = '/*' * (l.any - '*/')^0 * P('*/')^-1
local comment = token(l.COMMENT, line_comment + block_comment)

local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local string = token(l.STRING, sq_str + dq_str)

local number = token(l.NUMBER, l.digit^1 + l.float)

local keyword = token(l.KEYWORD, word_match {
  'graph', 'node', 'edge', 'digraph', 'fontsize', 'rankdir',
  'fontname', 'shape', 'label', 'arrowhead', 'arrowtail', 'arrowsize',
  'color', 'comment', 'constraint', 'decorate', 'dir', 'headlabel', 'headport',
  'headURL', 'labelangle', 'labeldistance', 'labelfloat', 'labelfontcolor',
  'labelfontname', 'labelfontsize', 'layer', 'lhead', 'ltail', 'minlen',
  'samehead', 'sametail', 'style', 'taillabel', 'tailport', 'tailURL', 'weight',
  'subgraph'
})

local type = token(l.TYPE, word_match {
	'box', 'polygon', 'ellipse', 'circle', 'point', 'egg', 'triangle',
	'plaintext', 'diamond', 'trapezium', 'parallelogram', 'house', 'pentagon',
	'hexagon', 'septagon', 'octagon', 'doublecircle', 'doubleoctagon',
	'tripleoctagon', 'invtriangle', 'invtrapezium', 'invhouse', 'Mdiamond',
	'Msquare', 'Mcircle', 'rect', 'rectangle', 'none', 'note', 'tab', 'folder',
	'box3d', 'record'
})

local operator = token(l.OPERATOR, S('->()[]{};'))

local identifier = token(l.IDENTIFIER, l.word)

_rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'keyword', keyword },
  { 'type', type },
  { 'identifier', identifier },
  { 'number', number },
  { 'string', string },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
