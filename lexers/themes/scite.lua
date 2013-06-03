-- Copyright 2006-2013 Mitchell mitchell.att.foicica.com. See LICENSE.
-- SciTE lexer theme for Scintillua.

local set_property = lexer.set_property

set_property('color.red', '#7F0000')
set_property('color.yellow', '#7F7F00')
set_property('color.green', '#007F00')
set_property('color.teal', '#007F7F')
set_property('color.purple', '#7F007F')
set_property('color.orange', '#B07F00')
set_property('color.blue', '#00007F')
set_property('color.black', '#000000')
set_property('color.grey', '#808080')
set_property('color.white', '#FFFFFF')

-- Default style.
local font, size = 'Monospace', 11
if WIN32 then
  font = 'Courier New'
elseif OSX then
  font, size = 'Monaco', 12
end
set_property('style.default', 'font:'..font..',size:'..size..
                              ',fore:$(color.black),back:$(color.white)')

-- Token styles.
set_property('style.nothing', '')
set_property('style.class', 'fore:$(color.black),bold')
set_property('style.comment', 'fore:$(color.green)')
set_property('style.constant', 'fore:$(color.teal),bold')
set_property('style.definition', 'fore:$(color.black),bold')
set_property('style.error', 'fore:$(color.red)')
set_property('style.function', 'fore:$(color.black),bold')
set_property('style.keyword', 'fore:$(color.blue),bold')
set_property('style.label', 'fore:$(color.teal),bold')
set_property('style.number', 'fore:$(color.teal)')
set_property('style.operator', 'fore:$(color.black),bold')
set_property('style.regex', '$(style.string)')
set_property('style.string', 'fore:$(color.purple)')
set_property('style.preproc', 'fore:$(color.yellow)')
set_property('style.tag', 'fore:$(color.teal)')
set_property('style.type', 'fore:$(color.blue)')
set_property('style.variable', 'fore:$(color.black)')
set_property('style.whitespace', '')
set_property('style.embedded', 'fore:$(color.blue)')
set_property('style.identifier', '$(style.nothing)')

-- Predefined styles.
set_property('style.linenumber', 'back:#C0C0C0')
set_property('style.bracelight', 'fore:#0000FF,bold')
set_property('style.bracebad', 'fore:#FF0000,bold')
set_property('style.controlchar', '$(style.nothing)')
set_property('style.indentguide', 'fore:#C0C0C0,back:$(color.white)')
set_property('style.calltip', 'fore:$(color.white),back:#444444')
