-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Gnuplot LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', '#' * nonnewline^0)

-- strings
local sq_str = delimited_range("'", '\\', true)
local dq_str = delimited_range('"', '\\', true)
local bk_str = delimited_range('[]', '\\', true, false, '\n')
local bc_str = delimited_range('{}', '\\', true, false, '\n')
local string = token('string', sq_str + dq_str + bk_str + bc_str)

-- keywords
local keyword = token('keyword', word_match(word_list{
  'cd', 'call', 'clear', 'exit', 'fit', 'help', 'history', 'if', 'load',
  'pause', 'plot', 'using', 'with', 'index', 'every', 'smooth', 'thru', 'print',
  'pwd', 'quit', 'replot', 'reread', 'reset', 'save', 'set', 'show', 'unset',
  'shell', 'splot', 'system', 'test', 'unset', 'update'
}))

-- functions
local func = token('function', word_match(word_list{
  'abs', 'acos', 'acosh', 'arg', 'asin', 'asinh', 'atan', 'atan2', 'atanh',
  'besj0', 'besj1', 'besy0', 'besy1', 'ceil', 'cos', 'cosh', 'erf', 'erfc',
  'exp', 'floor', 'gamma', 'ibeta', 'inverf', 'igamma', 'imag', 'invnorm',
  'int', 'lambertw', 'lgamma', 'log', 'log10', 'norm', 'rand', 'real', 'sgn',
  'sin', 'sinh', 'sqrt', 'tan', 'tanh', 'column', 'defined', 'tm_hour',
  'tm_mday', 'tm_min', 'tm_mon', 'tm_sec', 'tm_wday', 'tm_yday', 'tm_year',
  'valid'
}))

-- variables
local variable = token('variable', word_match(word_list{
  'angles', 'arrow', 'autoscale', 'bars', 'bmargin', 'border', 'boxwidth',
  'clabel', 'clip', 'cntrparam', 'colorbox', 'contour', 'datafile ',
  'decimalsign', 'dgrid3d', 'dummy', 'encoding', 'fit', 'fontpath', 'format',
  'functions', 'function', 'grid', 'hidden3d', 'historysize', 'isosamples',
  'key', 'label', 'lmargin', 'loadpath', 'locale', 'logscale', 'mapping',
  'margin', 'mouse', 'multiplot', 'mx2tics', 'mxtics', 'my2tics', 'mytics',
  'mztics', 'offsets', 'origin', 'output', 'parametric', 'plot', 'pm3d',
  'palette', 'pointsize', 'polar', 'print', 'rmargin', 'rrange', 'samples',
  'size', 'style', 'surface', 'terminal', 'tics', 'ticslevel', 'ticscale',
  'timestamp', 'timefmt', 'title', 'tmargin', 'trange', 'urange', 'variables',
  'version', 'view', 'vrange', 'x2data', 'x2dtics', 'x2label', 'x2mtics',
  'x2range', 'x2tics', 'x2zeroaxis', 'xdata', 'xdtics', 'xlabel', 'xmtics',
  'xrange', 'xtics', 'xzeroaxis', 'y2data', 'y2dtics', 'y2label', 'y2mtics',
  'y2range', 'y2tics', 'y2zeroaxis', 'ydata', 'ydtics', 'ylabel', 'ymtics',
  'yrange', 'ytics', 'yzeroaxis', 'zdata', 'zdtics', 'cbdata', 'cbdtics',
  'zero', 'zeroaxis', 'zlabel', 'zmtics', 'zrange', 'ztics', 'cblabel',
  'cbmtics', 'cbrange', 'cbtics'
}))

-- identifiers
local identifier = token('identifier', word)

-- operators
local operator = token('operator', S('-+~!$*%=<>&|^?:()'))

function LoadTokens()
  local gnuplot = gnuplot
  add_token(gnuplot, 'whitespace', ws)
  add_token(gnuplot, 'comment', comment)
  add_token(gnuplot, 'string', string)
  add_token(gnuplot, 'keyword', keyword)
  add_token(gnuplot, 'function', func)
  add_token(gnuplot, 'variable', variable)
  add_token(gnuplot, 'identifier', identifier)
  add_token(gnuplot, 'operator', operator)
  add_token(gnuplot, 'any_char', any_char)
end
