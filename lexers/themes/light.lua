-- Copyright 2006-2013 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Light lexer theme for Scintillua.
-- Contributions by Ana Balan.

local set_property = lexer.set_property

-- Greyscale colors.
--set_property('color.dark_black', '#000000')
--set_property('color.black', '#1A1A1A')
set_property('color.light_black', '#333333')
--set_property('color.grey_black', '#4D4D4D')
--set_property('color.dark_grey', '#666666')
set_property('color.grey', '#808080')
--set_property('color.light_grey', '#999999')
--set_property('grey_white', '#B3B3B3')
set_property('color.dark_white', '#CCCCCC')
set_property('color.white', '#E6E6E6')
--set_property('color.light_white', '#FFFFFF')

-- Dark colors.
--set_property('color.dark_red', '#661A1A')
set_property('color.dark_yellow', '#66661A')
set_property('color.dark_green', '#1A661A')
--set_property('color.dark_teal', '#1A6666')
--set_property('color.dark_purple', '#661A66')
set_property('color.dark_orange', '#B3661A')
--set_property('color.dark_pink', '#B36666')
set_property('color.dark_lavender', '#6666B3')
set_property('color.dark_blue', '#1A66B3')

-- Normal colors.
set_property('color.red', '#994D4D')
set_property('color.yellow', '#99994D')
set_property('color.green', '#4D994D')
set_property('color.teal', '#4D9999')
set_property('color.purple', '#994D99')
--set_property('color.orange', '#E6994D')
--set_property('color.pink', '#E69999')
set_property('color.lavender', '#9999E6')
--set_property('color.blue', '#4D99E6')

-- Light colors.
set_property('color.light_red', '#C08080')
--set_property('color.light_yellow', '#CCCC80')
--set_property('color.light_green', '#80CC80')
--set_property('color.light_teal', '#80CCCC')
--set_property('color.light_purple', '#CC80CC')
--set_property('color.light_orange', '#FFCC80')
--set_property('color.light_pink', '#FFCCCC')
--set_property('color.light_lavender', '#CCCCFF')
set_property('color.light_blue', '#80CCFF')

-- Default style.
local font, size = 'Bitstream Vera Sans Mono', 10
if WIN32 then
  font = 'Courier New'
elseif OSX then
  font, size = 'Monaco', 12
end
set_property('style.default', 'font:'..font..',size:'..size..
                              ',fore:$(color.light_black),back:$(color.white)')

-- Token styles.
set_property('style.nothing', '')
set_property('style.class', 'fore:$(color.yellow)')
set_property('style.comment', 'fore:$(color.grey)')
set_property('style.constant', 'fore:$(color.red)')
set_property('style.definition', 'fore:$(color.yellow)')
set_property('style.error', 'fore:$(color.red),italics')
set_property('style.function', 'fore:$(color.dark_orange)')
set_property('style.keyword', 'fore:$(color.dark_blue)')
set_property('style.label', 'fore:$(color.dark_orange)')
set_property('style.number', 'fore:$(color.teal)')
set_property('style.operator', 'fore:$(color.purple)')
set_property('style.regex', 'fore:$(color.dark_green)')
set_property('style.string', 'fore:$(color.green)')
set_property('style.preproc', 'fore:$(color.dark_yellow)')
set_property('style.tag', 'fore:$(color.dark_blue)')
set_property('style.type', 'fore:$(color.lavender)')
set_property('style.variable', 'fore:$(color.dark_lavender)')
set_property('style.whitespace', '')
set_property('style.embedded', '$(style.tag),back:$(color.dark_white)')
set_property('style.identifier', '$(style.nothing)')

-- Predefined styles.
set_property('style.linenumber', 'fore:$(color.grey),back:$(color.white)')
set_property('style.bracelight', 'fore:$(color.light_blue)')
set_property('style.bracebad', 'fore:$(color.light_red)')
set_property('style.controlchar', '$(style.nothing)')
set_property('style.indentguide',
             'fore:$(color.dark_white),black:$(color.dark_white)')
set_property('style.calltip',
             'fore:$(color.light_black),black:$(color.dark_white)')
