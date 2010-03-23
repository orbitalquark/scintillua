--------------------------------------------------------------------------------
-- The MIT License
--
-- Copyright (c) 2009 Martin Morawetz
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

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = (P('%') + '#') * nonnewline^0
local block_comment = '%{' * (any - '%}')^0 * P('%}')^-1
local comment = token('comment', block_comment + line_comment)

-- strings
local sq_str = delimited_range("'", '\\', true)
local dq_str = delimited_range('"', '\\', true)
local bt_str = delimited_range('`', '\\', true)
local string = token('string', sq_str + dq_str + bt_str)

-- numbers
local number = token('number', float + integer + dec_num + hex_num + oct_num)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'break', 'case', 'catch', 'continue', 'do', 'else', 'elseif',
  'end', 'end_try_catch', 'end_unwind_protect', 'endfor', 'endif',
  'endswitch', 'endwhile', 'for', 'function', 'endfunction',
  'global', 'if', 'otherwise', 'persistent', 'replot', 'return',
  'static', 'switch', 'try', 'until', 'unwind_protect',
  'unwind_protect_cleanup', 'varargin', 'varargout', 'while'
}, nil, true))

-- functions
local func = token('function', word_match(word_list{
  'abs', 'any', 'argv','atan2', 'axes', 'axis', 'ceil', 'cla', 'clear',
  'clf', 'columns', 'cos', 'delete', 'diff', 'disp', 'doc', 'double',
  'drawnow', 'exp', 'figure', 'find', 'fix', 'floor', 'fprintf',
  'gca', 'gcf', 'get', 'grid', 'help', 'hist', 'hold', 'isempty', 'isnull',
  'length', 'load', 'log', 'log10', 'loglog', 'max', 'mean', 'median',
  'min', 'mod', 'ndims', 'numel', 'num2str', 'ones', 'pause',
  'plot', 'printf', 'quit', 'rand', 'randn', 'rectangle', 'rem', 'repmat',
  'reshape', 'round', 'rows', 'save', 'semilogx', 'semilogy', 'set',
  'sign', 'sin', 'size', 'sizeof', 'size_equal', 'sort', 'sprintf',
  'squeeze', 'sqrt', 'std', 'strcmp', 'subplot', 'sum', 'tan', 'tic',
  'title', 'toc', 'uicontrol', 'who', 'xlabel', 'ylabel', 'zeros'
}))

-- constants
local constant = token('constant', word_match(word_list{
  'EDITOR', 'I', 'IMAGEPATH', 'INFO_FILE', 'J', 'LOADPATH',
  'OCTAVE_VERSION', 'PAGER', 'PS1', 'PS2', 'PS4', 'PWD'
}))

-- variable
local variable = token('variable', word_match(word_list{
  'ans', 'automatic_replot', 'default_return_value', 'do_fortran_indexing',
  'define_all_return_values', 'empty_list_elements_ok', 'eps', 'false',
  'gnuplot_binary',
  'ignore_function_time_stamp', 'implicit_str_to_num_ok', 'Inf', 'inf', 'NaN',
  'nan', 'ok_to_lose_imaginary_part', 'output_max_field_width', 'output_precision',
  'page_screen_output', 'pi', 'prefer_column_vectors', 'prefer_zero_one_indexing',
  'print_answer_id_name', 'print_empty_dimensions', 'realmax', 'realmin',
  'resize_on_range_error', 'return_last_computed_value', 'save_precision',
  'silent_functions', 'split_long_rows', 'suppress_verbose_help_message',
  'treat_neg_dim_as_zero', 'true', 'warn_assign_as_truth_value',
  'warn_comma_in_global_decl', 'warn_divide_by_zero', 'warn_function_name_clash',
  'whitespace_in_literal_matrix'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('!%^&*()[]{}-=+/\|:;.,?<>~`´'))

function LoadTokens()
  local matlab = matlab
  add_token(matlab, 'whitespace', ws)
  add_token(matlab, 'keyword', keyword)
  add_token(matlab, 'function', func)
  add_token(matlab, 'constant', constant)
  add_token(matlab, 'variable', variable)
  add_token(matlab, 'identifier', identifier)
  add_token(matlab, 'string', string)
  add_token(matlab, 'comment', comment)
  add_token(matlab, 'number', number)
  add_token(matlab, 'operator', operator)
  add_token(matlab, 'any_char', any_char)
end

function LoadStyles()
  add_style('function', style_function..{ fore = colors.red })
end
