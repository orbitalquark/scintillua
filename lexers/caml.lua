-- Copyright 2006-2026 Mitchell. See LICENSE.
-- OCaml LPeg lexer.
-- Migrated by Samuel Marquis.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(..., {fold_by_indentation = true})

-- Keywords.
lex:add_rule('keyword', lex:tag(lexer.KEYWORD, lex:word_match(lexer.KEYWORD)))

-- Types.
lex:add_rule('type', lex:tag(lexer.TYPE, lex:word_match(lexer.TYPE)))

-- Functions.
lex:add_rule('function', lex:tag(lexer.FUNCTION, lex:word_match(lexer.FUNCTION)))

-- Identifiers.
local word = (lexer.alnum + S("_'"))^1
lex:add_rule('identifier', lex:tag(lexer.IDENTIFIER, word))

-- Strings.
lex:add_rule('string', lex:tag(lexer.STRING, lexer.range('"'))

-- Comments.
lex:add_rule('comment', lex:tag(lexer.COMMENT, lexer.range('(*', '*)', false, false, true)))

-- Numbers.
lex:add_rule('number', lex:tag(lexer.NUMBER, lexer.number))

-- Operators.
lex:add_rule('operator', lex:tag(lexer.OPERATOR, S('=<>+-*/.,:;~!#%^&|?[](){}')))

lexer.property['scintillua.comment'] = '(*|*)'

lex:set_word_list(lexer.KEYWORD, {
	'and', 'as', 'asr', 'begin', 'class', 'closed', 'constraint', 'do', 'done',
	'downto', 'else', 'end', 'exception', 'external', 'failwith', 'false', 'flush',
	'for', 'fun', 'function', 'functor', 'if', 'in', 'include', 'incr', 'inherit',
	'land', 'let', 'load', 'los', 'lsl', 'lsr', 'lxor', 'match', 'method', 'mod',
	'module', 'mutable', 'new', 'not', 'of', 'open', 'option', 'or', 'parser',
	'private', 'raise', 'rec', 'ref', 'regexp', 'sig', 'stderr', 'stdin', 'stdout',
	'struct', 'then', 'to', 'true', 'try', 'type', 'val', 'virtual', 'when', 'while',
	'with'
})

lex:set_word_list(lexer.TYPE, {
	'bool', 'char', 'float', 'int', 'list', 'string', 'unit'
})

lex:set_word_list(lexer.FUNCTION, {
	'abs', 'abs_float', 'acos', 'asin', 'atan', 'atan2', 'at_exit', 'bool_of_string', 'ceil',
	'char_of_int', 'classify_float', 'close_in', 'close_in_noerr', 'close_out', 'close_out_noerr',
	'compare', 'cos', 'cosh', 'decr', 'epsilon_float', 'exit', 'exp', 'failwith', 'float',
	'float_of_int', 'float_of_string', 'floor', 'flush', 'flush_all', 'format_of_string', 'frexp',
	'fst', 'ignore', 'in_channel_length', 'incr', 'infinity', 'input', 'input_binary_int',
	'input_byte', 'input_char', 'input_line', 'input_value', 'int_of_char', 'int_of_float',
	'int_of_string', 'invalid_arg', 'ldexp', 'log', 'log10', 'max', 'max_float', 'max_int', 'min',
	'min_float', 'min_int', 'mod', 'modf', 'mod_float', 'nan', 'open_in', 'open_in_bin',
	'open_in_gen', 'open_out', 'open_out_bin', 'open_out_gen', 'out_channel_length', 'output',
	'output_binary_int', 'output_byte', 'output_char', 'output_string', 'output_value', 'pos_in',
	'pos_out', 'pred', 'prerr_char', 'prerr_endline', 'prerr_float', 'prerr_int', 'prerr_newline',
	'prerr_string', 'print_char', 'print_endline', 'print_float', 'print_int', 'print_newline',
	'print_string', 'raise', 'read_float', 'read_int', 'read_line', 'really_input', 'seek_in',
	'seek_out', 'set_binary_mode_in', 'set_binary_mode_out', 'sin', 'sinh', 'snd', 'sqrt', 'stderr',
	'stdin', 'stdout', 'string_of_bool', 'string_of_float', 'string_of_format', 'string_of_int',
	'succ', 'tan', 'tanh', 'truncate'
})
return lex
