# eXtra Source Import
# -------------------
test "imports", ->
  code = CoffeeScript.imports 'import "booleans"\nx = 1', filename: __dirname + '/src_imports.coffee'
  #console.log code
  ok /### imported/.test code