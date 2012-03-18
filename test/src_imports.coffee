# eXtra Source Import
# -------------------
test "imports", ->
  code = CoffeeScript.imports '#import "booleans"\nx = 1'
  #console.log code
  ok not /### imported/.test code
  code = CoffeeScript.imports 'import "booleans"\nx = 1', filename: __dirname + '/src_imports.coffee'
  #console.log code
  ok /### imported/.test code
  code = CoffeeScript.imports 'import "src_imports_test.js"\nx = 1', filename: __dirname + '/src_imports.coffee'
  #console.log code, code.indexOf("\\x60js\\x60")
  ok code.indexOf("\\x60js\\x60") > 0
