-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Erlang LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', '%' * nonnewline^0)

-- strings
local sq_str = delimited_range("'", '\\', true, false, '\n')
local dq_str = delimited_range('"', '\\', true)
local literal = '$' * any * alnum^0
local string = token('string', sq_str + dq_str + literal)

-- numbers
local number = token('number', float + integer)

-- directives
local directive = token('directive', '-' * word_match(word_list{
  'author', 'compile', 'copyright', 'define', 'doc', 'else', 'endif', 'export',
  'file', 'ifdef', 'ifndef', 'import', 'include_lib', 'include', 'module',
  'record', 'undef'
}))

-- keywords
local keyword = token('keyword', word_match(word_list{
  'after', 'begin', 'case', 'catch', 'cond', 'end', 'fun', 'if', 'let', 'of',
  'query', 'receive', 'when',
  -- operators
  'div', 'rem', 'or', 'xor', 'bor', 'bxor', 'bsl', 'bsr', 'and', 'band', 'not',
  'bnot',
  'badarg', 'nocookie', 'false', 'true'
}))

-- functions
local func = token('function', word_match(word_list{
  'abs', 'alive', 'apply', 'atom_to_list', 'binary_to_list', 'binary_to_term',
  'concat_binary', 'date', 'disconnect_node', 'element', 'erase', 'exit',
  'float', 'float_to_list', 'get', 'get_keys', 'group_leader', 'halt', 'hd',
  'integer_to_list', 'is_alive', 'length', 'link', 'list_to_atom',
  'list_to_binary', 'list_to_float', 'list_to_integer', 'list_to_pid',
  'list_to_tuple', 'load_module', 'make_ref', 'monitor_node', 'node', 'nodes',
  'now', 'open_port', 'pid_to_list', 'process_flag', 'process_info', 'process',
  'put', 'register', 'registered', 'round', 'self', 'setelement', 'size',
  'spawn', 'spawn_link', 'split_binary', 'statistics', 'term_to_binary',
  'throw', 'time', 'tl', 'trunc', 'tuple_to_list', 'unlink', 'unregister',
  'whereis',
  -- others
  'atom', 'binary', 'constant', 'function', 'integer', 'list', 'number', 'pid',
  'ports', 'port_close', 'port_info', 'reference', 'record',
  -- erlang:
  'check_process_code', 'delete_module', 'get_cookie', 'hash', 'math',
  'module_loaded', 'preloaded', 'processes', 'purge_module', 'set_cookie',
  'set_node',
  -- math
  'acos', 'asin', 'atan', 'atan2', 'cos', 'cosh', 'exp', 'log', 'log10', 'pi',
  'pow', 'power', 'sin', 'sinh', 'sqrt', 'tan', 'tanh'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('-<>.;=/|#+*:,?!()[]{}'))

function LoadTokens()
  local erlang = erlang
  add_token(erlang, 'whitespace', ws)
  add_token(erlang, 'comment', comment)
  add_token(erlang, 'string', string)
  add_token(erlang, 'number', number)
  add_token(erlang, 'directive', directive)
  add_token(erlang, 'keyword', keyword)
  add_token(erlang, 'function', func)
  add_token(erlang, 'identifier', identifier)
  add_token(erlang, 'operator', operator)
  add_token(erlang, 'any_char', any_char)
end

function LoadStyles()
  add_style('directive', style_preproc)
end
