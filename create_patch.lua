local p = io.popen('grep -rlI --exclude-dir=".hg" Mitchell scintillua/scintilla | sort')
local patch = ''
for file in p:lines() do
  local scintilla_file = file:gsub('scintillua/scintilla', 'scite-latest/scintilla')
  print('diffing '..scintilla_file..' to '..file)
  local d = io.popen('diff -Naur '..scintilla_file..' '..file)
  patch = patch..d:read('*all')
  d:close()
end
p:close()

local f = io.open('scintillua.patch', 'w')
f:write(patch)
f:close()

local p = io.popen('grep -rlI --exclude-dir=".hg" Mitchell scintillua/scite | sort')
local patch = ''
for file in p:lines() do
  local scite_file = file:gsub('scintillua/scite', 'scite-latest/scite')
  print('diffing '..scite_file..' to '..file)
  local d = io.popen('diff -Naur '..scite_file..' '..file)
  patch = patch..d:read('*all')
  d:close()
end
p:close()

local f = io.open('scintillua.patch', 'a')
f:write(patch)
f:close()
