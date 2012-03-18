# eXtra Source Minify
# -------------------
test "minify", ->
  code = CoffeeScript.minify 'var a = true;'
  # console.log code
  ok /a=!0/.test code
  code = CoffeeScript.compile 'a = yes', minify: on, bare: on
  # console.log code
  ok /a=!0/.test code
  code = CoffeeScript.compile 'a = yes', min: on
  #console.log code
  ok /a=!0/.test code
