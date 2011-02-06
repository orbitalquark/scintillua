#!/usr/bin/lua

local format, concat = string.format, table.concat

-- Do not glob these files. (e.g. *.foo)
local noglobs = {
  GNUmakefile = true,
  Makefile = true,
  makefile = true,
  Rakefile = true,
  ['Rout.save'] = true,
  ['Rout.fail'] = true,
}

-- Process file patterns and lexer definitions from Textadept.
local output = { '# Lexer definitions (' }
local lexer, ext
local exts = {}
for line in io.lines('../textadept/modules/textadept/mime_types.conf') do
  if line:match('^%%') then
    if #exts > 0 then
      output[#output + 1] = format('file.patterns.%s=%s', lexer,
                                   concat(exts, ';'))
      output[#output + 1] = format('lexer.$(file.patterns.%s)=lpeg_%s', lexer,
                                   lexer)
      exts = {}
    end
  elseif line:match('^[^#/%s]') then
    ext, lexer = line:match('^(%S+) (%S+)')
    exts[#exts + 1] = not noglobs[ext] and '*.'..ext or ext
  end
end
output[#output + 1] = '# )'

-- Write to lpeg.properties.
local f = io.open('lexers/lpeg.properties')
local text = f:read('*all')
text = text:gsub('# Lexer definitions %b()', table.concat(output, '\n'), 1)
f:close()
f = io.open('lexers/lpeg.properties', 'wb')
f:write(text)
f:close()
