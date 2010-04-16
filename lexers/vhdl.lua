-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- VHDL LPeg lexer

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S

module(...)

local ws = token('whitespace', l.space^1)

-- comments
local comment = token('comment', '--' * l.nonnewline^0)

-- strings
local sq_str = l.delimited_range("'", nil, true, false, '\n')
local dq_str = l.delimited_range('"', '\\', true, false, '\n')
local string = token('string', sq_str + dq_str)

-- numbers
local number = token('number', l.float + l.integer)

-- keywords
local keyword = token('keyword', word_match {
  'access', 'after', 'alias', 'all', 'architecture', 'array', 'assert',
  'attribute', 'begin', 'block', 'body', 'buffer', 'bus', 'case', 'component',
  'configuration', 'constant', 'disconnect', 'downto', 'else', 'elsif', 'end',
  'entity', 'exit', 'file', 'for', 'function', 'generate', 'generic', 'group',
  'guarded', 'if', 'impure', 'in', 'inertial', 'inout', 'is', 'label',
  'library', 'linkage', 'literal', 'loop', 'map', 'new', 'next', 'null', 'of',
  'on', 'open', 'others', 'out', 'package', 'port', 'postponed', 'procedure',
  'process', 'pure', 'range', 'record', 'register', 'reject', 'report',
  'return', 'select', 'severity', 'signal', 'shared', 'subtype', 'then', 'to',
  'transport', 'type', 'unaffected', 'units', 'until', 'use', 'variable',
  'wait', 'when', 'while', 'with', 'note', 'warning', 'error', 'failure',
  'and', 'nand', 'or', 'nor', 'xor', 'xnor', 'rol', 'ror', 'sla', 'sll', 'sra',
  'srl', 'mod', 'rem', 'abs', 'not',
  'false', 'true'
})

-- functions
local func = token('function', word_match {
  'rising_edge', 'shift_left', 'shift_right', 'rotate_left', 'rotate_right',
  'resize', 'std_match', 'to_integer', 'to_unsigned', 'to_signed', 'unsigned',
  'signed', 'to_bit', 'to_bitvector', 'to_stdulogic', 'to_stdlogicvector',
  'to_stdulogicvector'
})

-- types
local type = token('type', word_match {
  'bit', 'bit_vector', 'character', 'boolean', 'integer', 'real', 'time',
  'string', 'severity_level', 'positive', 'natural', 'signed', 'unsigned',
  'line', 'text', 'std_logic', 'std_logic_vector', 'std_ulogic',
  'std_ulogic_vector', 'qsim_state', 'qsim_state_vector', 'qsim_12state',
  'qsim_12state_vector', 'qsim_strength', 'mux_bit', 'mux_vectory', 'reg_bit',
  'reg_vector', 'wor_bit', 'wor_vector'
})

-- constants
local constant = token('constant', word_match {
  'EVENT', 'BASE', 'LEFT', 'RIGHT', 'LOW', 'HIGH', 'ASCENDING', 'IMAGE',
  'VALUE', 'POS', 'VAL', 'SUCC', 'VAL', 'POS', 'PRED', 'VAL', 'POS', 'LEFTOF',
  'RIGHTOF', 'LEFT', 'RIGHT', 'LOW', 'HIGH', 'RANGE', 'REVERSE', 'LENGTH',
  'ASCENDING', 'DELAYED', 'STABLE', 'QUIET', 'TRANSACTION', 'EVENT', 'ACTIVE',
  'LAST', 'LAST', 'LAST', 'DRIVING', 'DRIVING', 'SIMPLE', 'INSTANCE', 'PATH'
})

-- identifiers
local word = (l.alpha + "'") * (l.alnum + "_" + "'")^1
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('=/!:;<>+-/*%&|^~()'))

_rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'function', func },
  { 'type', type },
  { 'constant', constant },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}
