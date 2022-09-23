#!/usr/bin/lua

local format, concat = string.format, table.concat

-- Do not glob these files. (e.g. *.foo)
local noglobs = {
  Dockerfile = true, GNUmakefile = true, Makefile = true, makefile = true, Rakefile = true,
  ['Rout.save'] = true, ['Rout.fail'] = true, fstab = true, ['meson.build'] = true
}

local alt_name = {
  actionscript = 'flash', ansi_c = 'c', dmd = 'd', javascript = 'js', python = 'py', rstats = 'r',
  ruby = 'rb'
}

-- Process file patterns and lexer definitions.
local f = io.open('lexers/lexer.lua')
local definitions = f:read('*all'):match('local extensions = (%b{})')
f:close()

local output = {'# Lexer definitions ('}
local lexer, ext, last_lexer
local exts = {}
for ext, lexer in definitions:gmatch("([^,'%]]+)'?%]?='([%w_]+)'") do
  if lexer ~= last_lexer and #exts > 0 then
    local name = alt_name[last_lexer] or last_lexer
    output[#output + 1] = format('file.patterns.%s=%s', name, concat(exts, ';'))
    output[#output + 1] = format('lexer.$(file.patterns.%s)=scintillua.%s', name, last_lexer)
    exts = {}
  end
  exts[#exts + 1] = not noglobs[ext] and '*.' .. ext or ext
  last_lexer = lexer
end
local name = alt_name[last_lexer] or last_lexer
output[#output + 1] = format('file.patterns.%s=%s', name, concat(exts, ';'))
output[#output + 1] = format('lexer.$(file.patterns.%s)=scintillua.%s', name, last_lexer)
output[#output + 1] = '# )'

-- Write to lpeg.properties.
f = io.open('scintillua.properties')
local text = f:read('*all')
text = text:gsub('# Lexer definitions %b()', table.concat(output, '\n'), 1)
f:close()
f = io.open('scintillua.properties', 'wb')
f:write(text)
f:close()
