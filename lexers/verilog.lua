-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Verilog LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token(l.WHITESPACE, l.space^1)

-- comments
local line_comment = '//' * l.nonnewline^0
local block_comment = '/*' * (l.any - '*/')^0 * P('*/')^-1
local comment = token(l.COMMENT, line_comment + block_comment)

-- strings
local string = token(l.STRING, l.delimited_range('"', '\\', true))

-- numbers
local bin_suffix = S('bB') * S('01_xXzZ')^1
local oct_suffix = S('oO') * S('01234567_xXzZ')^1
local dec_suffix = S('dD') * S('0123456789_xXzZ')^1
local hex_suffix = S('hH') * S('0123456789abcdefABCDEF_xXzZ')^1
local number = token(l.NUMBER, (l.digit + '_')^1 + "'" *
                     (bin_suffix + oct_suffix + dec_suffix + hex_suffix))

-- keywords
local keyword = token(l.KEYWORD, word_match({
  'always', 'assign', 'begin', 'case', 'casex', 'casez', 'default', 'deassign',
  'disable', 'else', 'end', 'endcase', 'endfunction', 'endgenerate',
  'endmodule', 'endprimitive', 'endspecify', 'endtable', 'endtask', 'for',
  'force', 'forever', 'fork', 'function', 'generate', 'if', 'initial', 'join',
  'macromodule', 'module', 'negedge', 'posedge', 'primitive', 'repeat',
  'release', 'specify', 'table', 'task', 'wait', 'while',
  -- compiler directives
  '`include', '`define', '`undef', '`ifdef', '`ifndef', '`else', '`endif',
  '`timescale', '`resetall', '`signed', '`unsigned', '`celldefine',
  '`endcelldefine', '`default_nettype', '`unconnected_drive',
  '`nounconnected_drive', '`protect', '`endprotect', '`protected',
  '`endprotected', '`remove_gatename', '`noremove_gatename', '`remove_netname',
  '`noremove_netname', '`expand_vectornets', '`noexpand_vectornets',
  '`autoexpand_vectornets',
  -- signal strengths
  'strong0', 'strong1', 'pull0', 'pull1', 'weak0', 'weak1', 'highz0', 'highz1',
  'small', 'medium', 'large'
}, '`01'))

-- function
local func = token(l.FUNCTION, word_match({
  '$stop', '$finish', '$time', '$stime', '$realtime', '$settrace',
  '$cleartrace', '$showscopes', '$showvars', '$monitoron', '$monitoroff',
  '$random', '$printtimescale', '$timeformat', '$display',
  -- built-in primitives
  'and', 'nand', 'or', 'nor', 'xor', 'xnor', 'buf', 'bufif0', 'bufif1', 'not',
  'notif0', 'notif1', 'nmos', 'pmos', 'cmos', 'rnmos', 'rpmos', 'rcmos', 'tran',
  'tranif0', 'tranif1', 'rtran', 'rtranif0', 'rtranif1', 'pullup', 'pulldown'
}, '$01'))

-- types
local type = token(l.TYPE, word_match({
  'integer', 'reg', 'time', 'realtime', 'defparam', 'parameter', 'event',
  'wire', 'wand', 'wor', 'tri', 'triand', 'trior', 'tri0', 'tri1', 'trireg',
  'vectored', 'scalared', 'input', 'output', 'inout',
  'supply0', 'supply1'
}, '01'))

-- identifiers
local identifier = token(l.IDENTIFIER, l.word)

-- operators
local operator = token(l.OPERATOR, S('=~+-/*<>%&|^~,:;()[]{}'))

_rules = {
  { 'whitespace', ws },
  { 'number', number },
  { 'keyword', keyword },
  { 'function', func },
  { 'type', type },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
