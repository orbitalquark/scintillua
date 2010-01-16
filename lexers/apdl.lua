-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- APDL LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local comment = token('comment', '!' * nonnewline^0)

-- strings
local string = token('string', delimited_range("'", nil, true, false, '\n'))

-- numbers
local number = token('number', float + integer)

-- keywords
local keyword = token('keyword', word_match(word_list{
  '*abbr', '*abb', '*afun', '*afu', '*ask', '*cfclos', '*cfc', '*cfopen',
  '*cfo', '*cfwrite', '*cfw', '*create', '*cre', '*cycle', '*cyc', '*del',
  '*dim', '*do', '*elseif', '*else', '*enddo', '*endif', '*end', '*eval',
  '*eva', '*exit', '*exi', '*get', '*go', '*if', '*list', '*lis', '*mfouri',
  '*mfo', '*mfun', '*mfu', '*mooney', '*moo', '*moper', '*mop', '*msg',
  '*repeat', '*rep', '*set', '*status', '*sta', '*tread', '*tre', '*ulib',
  '*uli', '*use', '*vabs', '*vab', '*vcol', '*vco', '*vcum', '*vcu', '*vedit',
  '*ved', '*vfact', '*vfa', '*vfill', '*vfi', '*vfun', '*vfu', '*vget', '*vge',
  '*vitrp', '*vit', '*vlen', '*vle', '*vmask', '*vma', '*voper', '*vop',
  '*vplot', '*vpl', '*vput', '*vpu', '*vread', '*vre', '*vscfun', '*vsc',
  '*vstat', '*vst', '*vwrite', '*vwr', '/anfile', '/anf', '/angle', '/ang',
  '/annot', '/ann', '/anum', '/anu', '/assign', '/ass', '/auto', '/aut',
  '/aux15', '/aux2', '/aux', '/axlab', '/axl', '/batch', '/bat', '/clabel',
  '/cla', '/clear', '/cle', '/clog', '/clo', '/cmap', '/cma', '/color', '/col',
  '/com', '/config', '/contour', '/con', '/copy', '/cop', '/cplane', '/cpl',
  '/ctype', '/cty', '/cval', '/cva', '/delete', '/del', '/devdisp', '/device',
  '/dev', '/dist', '/dis', '/dscale', '/dsc', '/dv3d', '/dv3', '/edge', '/edg',
  '/efacet', '/efa', '/eof', '/erase', '/era', '/eshape', '/esh', '/exit',
  '/exi', '/expand', '/exp', '/facet', '/fac', '/fdele', '/fde', '/filname',
  '/fil', '/focus', '/foc', '/format', '/for', '/ftype', '/fty', '/gcmd',
  '/gcm', '/gcolumn', '/gco', '/gfile', '/gfi', '/gformat', '/gfo', '/gline',
  '/gli', '/gmarker', '/gma', '/golist', '/gol', '/gopr', '/gop', '/go',
  '/graphics', '/gra', '/gresume', '/gre', '/grid', '/gri', '/gropt', '/gro',
  '/grtyp', '/grt', '/gsave', '/gsa', '/gst', '/gthk', '/gth', '/gtype', '/gty',
  '/header', '/hea', '/input', '/inp', '/larc', '/lar', '/light', '/lig',
  '/line', '/lin', '/lspec', '/lsp', '/lsymbol', '/lsy', '/menu', '/men',
  '/mplib', '/mpl', '/mrep', '/mre', '/mstart', '/mst', '/nerr', '/ner',
  '/noerase', '/noe', '/nolist', '/nol', '/nopr', '/nop', '/normal', '/nor',
  '/number', '/num', '/opt', '/output', '/out', '/page', '/pag', '/pbc', '/pbf',
  '/pcircle', '/pci', '/pcopy', '/pco', '/plopts', '/plo', '/pmacro', '/pma',
  '/pmeth', '/pme', '/pmore', '/pmo', '/pnum', '/pnu', '/polygon', '/pol',
  '/post26', '/post1', '/pos', '/prep7', '/pre', '/psearch', '/pse', '/psf',
  '/pspec', '/psp', '/pstatus', '/pst', '/psymb', '/psy', '/pwedge', '/pwe',
  '/quit', '/qui', '/ratio', '/rat', '/rename', '/ren', '/replot', '/rep',
  '/reset', '/res', '/rgb', '/runst', '/run', '/seclib', '/sec', '/seg',
  '/shade', '/sha', '/showdisp', '/show', '/sho', '/shrink', '/shr', '/solu',
  '/sol', '/sscale', '/ssc', '/status', '/sta', '/stitle', '/sti', '/syp',
  '/sys', '/title', '/tit', '/tlabel', '/tla', '/triad', '/tri', '/trlcy',
  '/trl', '/tspec', '/tsp', '/type', '/typ', '/ucmd', '/ucm', '/uis', '/ui',
  '/units', '/uni', '/user', '/use', '/vcone', '/vco', '/view', '/vie',
  '/vscale', '/vsc', '/vup', '/wait', '/wai', '/window', '/win', '/xrange',
  '/xra', '/yrange', '/yra', '/zoom', '/zoo'
}, '*/', true))

-- identifiers
local identifier = token('identifier', word)

-- functions
local func = token('function', delimited_range('%', nil, false, false, '\n'))

-- labels
local label = token('label', #P(':') * starts_line(':' * word))

-- operators
local operator = token('operator', S('+-*/$=,;()'))

function LoadTokens()
  local apdl = apdl
  add_token(apdl, 'whitespace', ws)
  add_token(apdl, 'keyword', keyword)
  add_token(apdl, 'identifier', identifier)
  add_token(apdl, 'string', string)
  add_token(apdl, 'number', number)
  add_token(apdl, 'function', func)
  add_token(apdl, 'label', label)
  add_token(apdl, 'comment', comment)
  add_token(apdl, 'operator', operator)
  add_token(apdl, 'any_char', any_char)
end

function LoadStyles()
  add_style('label', style_constant)
end
