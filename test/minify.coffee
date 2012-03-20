# eXtra Source Minify
# -------------------
test "minify", ->
  code = CoffeeScript.minify 'var a = true;'
  # console.log code
  ok /a=!0/.test code

test "compile with minify and bare", ->
  code = CoffeeScript.compile 'a = yes', minify: on, bare: on
  # console.log code
  ok /a=!0/.test code

test "compile with min", ->
  code = CoffeeScript.compile 'a = yes', min: on
  #console.log code
  ok /a=!0/.test code

test "compile with minify default no_ascii is on", ->
  code = CoffeeScript.compile 'b = "\xff"', min: on
  console.log code
  ok /"\\(?:u00ff|xff)"/.test code

test "compile with minify default inline_script is on", ->
  code = CoffeeScript.compile 'c = "</script"+">"', min: on
  # console.log code
  ok /"<\\\/script>"/.test code
