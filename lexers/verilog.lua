-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Verilog LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = '//' * nonnewline^0
local block_comment = '/*' * (any - '*/')^0 * P('*/')^-1
local comment = token('comment', line_comment + block_comment)

-- strings
local string = token('string', delimited_range('"', '\\', true))

-- numbers
local bin_suffix = S('bB') * S('01_xXzZ')^1
local oct_suffix = S('oO') * S('01234567_xXzZ')^1
local dec_suffix = S('dD') * S('0123456789_xXzZ')^1
local hex_suffix = S('hH') * S('0123456789abcdefABCDEF_xXzZ')^1
local number = token('number', (digit + '_')^1 + "'" *
  (bin_suffix + oct_suffix + dec_suffix + hex_suffix))

-- keywords
local keyword = token('keyword', word_match(word_list{
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
local func = token('function', word_match(word_list{
  '$stop', '$finish', '$time', '$stime', '$realtime', '$settrace',
  '$cleartrace', '$showscopes', '$showvars', '$monitoron', '$monitoroff',
  '$random', '$printtimescale', '$timeformat', '$display',
  -- built-in primitives
  'and', 'nand', 'or', 'nor', 'xor', 'xnor', 'buf', 'bufif0', 'bufif1', 'not',
  'notif0', 'notif1', 'nmos', 'pmos', 'cmos', 'rnmos', 'rpmos', 'rcmos', 'tran',
  'tranif0', 'tranif1', 'rtran', 'rtranif0', 'rtranif1', 'pullup', 'pulldown'
}, '$01'))

-- types
local type = token('type', word_match(word_list{
  'integer', 'reg', 'time', 'realtime', 'defparam', 'parameter', 'event',
  'wire', 'wand', 'wor', 'tri', 'triand', 'trior', 'tri0', 'tri1', 'trireg',
  'vectored', 'scalared', 'input', 'output', 'inout',
  'supply0', 'supply1'
}, '01'))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('=~+-/*<>%&|^~,:;()[]{}'))

function LoadTokens()
  local verilog = verilog
  add_token(verilog, 'whitespace', ws)
  add_token(verilog, 'number', number)
  add_token(verilog, 'keyword', keyword)
  add_token(verilog, 'function', func)
  add_token(verilog, 'type', type)
  add_token(verilog, 'identifier', identifier)
  add_token(verilog, 'string', string)
  add_token(verilog, 'comment', comment)
  add_token(verilog, 'operator', operator)
  add_token(verilog, 'any_char', any_char)
end
