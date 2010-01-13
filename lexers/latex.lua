-- Copyright 2006-2010 Mitchell mitchell<att>caladbolg.net. See LICENSE.
-- Latex LPeg lexer

module(..., package.seeall)
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local ws = token('whitespace', space^1)

-- comments
local line_comment = '%' * nonnewline^0
local block_comment = '\\begin{comment}' * (any - '\\end{comment}')^0 *
  '\\end{comment}'
local comment = token('comment', line_comment + block_comment)

-- strings
local math_string = '$$' * (any - '$$')^0 * '$$' +
  delimited_range('$', '\\', true, false, '\n')
local string = token('string', math_string)

-- environment
local env_word = word_match(word_list{
  'abstract', 'array', 'center', 'description', 'displaymath', 'document',
  'enumerate', 'eqnarray', 'equation', 'figure', 'flushleft', 'flushright',
  'itemize', 'list', 'math', 'minipage', 'picture', 'quotation', 'quote',
  'tabbing', 'table', 'tabular', 'thebibliography', 'theorem', 'titlepage',
  'trivlist', 'verbatim', 'verse'
})
local environment =
  token('tag', '\\' * (P('begin') + 'end') * '{' * env_word * '}')

-- commands
local cmd_word = word_match(word_list{
  'addcontentsline', 'addtocontents', 'addtocounter', 'address', 'addtolength',
  'addvspace', 'alpha', 'appendix', 'arabic', 'author', 'backslash',
  'baselineskip', 'baselinestretch', 'bf', 'bibitem', 'bigskip', 'boldmath',
  'cal', 'caption', 'cdots', 'centering', 'circle', 'centering', 'circle',
  'cite', 'cleardoublepage', 'clearpage', 'cline', 'closing', 'dashbox', 'date',
  'ddots', 'dotfill', 'em', 'ensuremath', 'fbox', 'flushbottom', 'fnsymbol',
  'footnote', 'footnotemark', 'footnotesize', 'footnotetext', 'frac', 'frame',
  'framebox', 'frenchspacing', 'hfill', 'hline', 'hrulefill', 'hspace', 'huge',
  'Huge', 'hyphenation', 'include', 'includeonly', 'indent', 'input', 'it',
  'item', 'kill', 'label', 'large', 'Large', 'LARGE', 'ldots', 'left',
  'lefteqn', 'line', 'linebreak', 'linethickness', 'linewidth', 'location',
  'makebox', 'maketitle', 'markboth', 'markright', 'mathcal', 'mathop', 'mbox',
  'medskip', 'multicolumn', 'multiput', 'newcommand', 'newcounter',
  'newenvironment', 'newfont', 'newlength', 'newline', 'newpage', 'newsavebox',
  'newtheorem', 'nocite', 'noindent', 'nolinebreak', 'normalsize',
  'nopagebreak', 'not', 'onecolumn', 'opening', 'oval', 'overbrece', 'overline',
  'pagebreak', 'pagenumbering', 'pageref', 'pagestyle', 'par', 'parbox',
  'parindent', 'parskip', 'protect', 'providecommand', 'put', 'raggedbottom',
  'raggedright', 'raisebox', 'ref', 'refnewcommand', 'right', 'rm', 'roman',
  'rule', 'savebox', 'sbox', 'sc', 'scriptsize', 'setcounter', 'setlength',
  'settowidth', 'sf', 'shortstack', 'signature', 'sl', 'small', 'smallskip',
  'sqrt', 'stackrel', 'tableofcontents', 'telephone', 'textwidth', 'textheight',
  'thanks', 'thispagestyle', 'tiny', 'title', 'today', 'tt', 'twocolumn',
  'typeout', 'typein', 'underbrace', 'underline', 'unitlength', 'usebox',
  'usecounter', 'value', 'vdots', 'vector', 'verb', 'vfill', 'vline',
  'vphantom', 'vspace', 'documentclass',
  -- TODO: math for tex?
  -- characters
  'alpha', 'aeta', 'chi', 'delta', 'epsilon', 'eta', 'gamma', 'iota', 'kappa',
  'lambda', 'leftarrow', 'leftrightarrow', 'mu', 'nu', 'omega', 'phi', 'pi',
  'psi', 'rho', 'rightarrow', 'sigma', 'tau', 'zeta',
})
local math_word = word_match(word_list{
  'hat', 'widehat', 'check', 'tilde', 'widetilde', 'acute', 'grave', 'dot',
  'ddot', 'breve', 'bar', 'vec'
})
local cmd_sym = punct
local command = token('keyword', '\\' * (cmd_word + cmd_sym + math_word))

-- operators
local operator = token('operator', S('$&%#{}'))

function LoadTokens()
  local latex = latex
  add_token(latex, 'whitespace', ws)
  add_token(latex, 'comment', comment)
  add_token(latex, 'string', string)
  add_token(latex, 'tag', environment)
  add_token(latex, 'keyword', command)
  add_token(latex, 'operator', operator)
  add_token(latex, 'any_char', any_char)
end

function LoadStyles()
  add_style('tag', style_tag)
end
