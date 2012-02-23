# eXtra Strict Mode
# -----------------
test "strict mode", ->
  code = CoffeeScript.compile 'x = 1', strict: on, header: off, bare: off
  #console.log code
  ok /^\(function\(\) \{\n"use strict";\n/.test code
  code = CoffeeScript.compile 'x = 1', strict: on, header: off, bare: on
  #console.log code
  ok /^"use strict";\n/.test code
