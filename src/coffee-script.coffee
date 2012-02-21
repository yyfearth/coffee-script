# CoffeeScript can be used both on the server, as a command-line compiler based
# on Node.js/V8, or to run CoffeeScripts directly in the browser. This module
# contains the main entry functions for tokenizing, parsing, and compiling
# source CoffeeScript into JavaScript.
#
# If included on a webpage, it will automatically sniff out, compile, and
# execute all scripts present in `text/coffeescript` tags.

fs               = require 'fs'
path             = require 'path'
{Lexer,RESERVED} = require './lexer'
{parser}         = require './parser'
vm               = require 'vm'
iced             = require './iced'

# Native extensions we're willing to consider
exports.EXTENSIONS = EXTENSIONS = [ ".coffee", ".xcoffee", ".iced" ]

isCoffeeFile = (file) ->
  for e in EXTENSIONS
    return true if path.extname(file) is e
  false

# TODO: Remove registerExtension when fully deprecated.
if require.extensions
  for e in EXTENSIONS
    require.extensions[e] = (module, filename) ->
      content = compile fs.readFileSync(filename, 'utf8'), {filename}
      module._compile content, filename
else if require.registerExtension
  for e in EXTENSIONS
    require.registerExtension e, (content) -> compile content

# The current CoffeeScript version number.
exports.VERSION = '1.2.0q'

# Words that cannot be used as identifiers in CoffeeScript code
exports.RESERVED = RESERVED

# Expose helpers for testing.
exports.helpers = require './helpers'

# import by wilson
exports.imports = imports = (code, options = {}) ->
  regex = options.regex or /^\s*import\s+['"](.+)['"][;\s]*$/
  regex_g = new RegExp regex.source, 'gm'
  chk_file = (filename) ->
    try
      stats = fs.lstatSync filename
      return not stats.isDirectory()
    catch e
      return false
  #console.log options
  filename = options.filename or null
  cwd = process.cwd()
  imported = {}
  do parse = (code, filename) ->
    code.replace regex_g, (match) ->
      match = match.match regex
      dir = if filename then path.dirname fs.realpathSync filename else cwd
      _filename = f = path.resolve dir, match[1]
      unless chk_file _filename
        _filename = null
        exts = EXTENSIONS.concat ['.js']
        while not _filename and (ext = exts.shift())
          _filename = f + ext if chk_file f + ext
        throw "In #{filename}, cannot find import: #{f}" unless _filename
      throw "In #{filename}, find duplicate import: #{_filename}" if imported[_filename]
      is_js = /\.js$/.test filename
      _is_js = /\.js$/.test _filename
      if is_js and not _is_js
        throw "In #{filename}, Js file cannot include non-js file #{_filename}"
      import_code = fs.readFileSync _filename, 'utf8'
      imported[_filename] = true
      import_code = parse import_code, _filename
      import_code = "`#{import_code}`" if is_js isnt _is_js # if coffee import js
      #console.log 'import', _filename, import_code
      rmk = if /\.js$/.test filename then "/* imported #{_filename} */" else "### imported #{_filename} ###"
      "#{rmk}\n#{import_code}\n\n"
# end of import

# Compile a string of CoffeeScript code to JavaScript, using the Coffee/Jison
# compiler.
exports.compile = compile = (code, options = {}) ->
  # import add by wilson
  code = imports code, options if options.imports

  {merge} = exports.helpers
  try
    js = (iced.transform parser.parse lexer.tokenize code).compile options
    return js unless options.header
  catch err
    console.log 'imported finished code:', code if options.imports
    err.message = "In #{options.filename}, #{err.message}" if options.filename
    throw err
  header = if typeof options.header is 'string' then options.header else "Generated by eXtraCoffeeScript #{@VERSION}"
  "// #{header}\n#{js}"

# Tokenize a string of CoffeeScript code, and return the array of tokens.
exports.tokens = (code, options) ->
  lexer.tokenize code, options

# Parse a string of CoffeeScript code or an array of lexed tokens, and
# return the AST. You can then compile it by calling `.compile()` on the root,
# or traverse it by using `.traverseChildren()` with a callback.
exports.nodes = (source, options) ->
  if typeof source is 'string'
    iced.transform parser.parse lexer.tokenize source, options
  else
    iced.transform parser.parse source

# Compile and execute a string of CoffeeScript (on the server), correctly
# setting `__filename`, `__dirname`, and relative `require()`.
exports.run = (code, options = {}) ->
  mainModule = require.main

  # Set the filename.
  mainModule.filename = process.argv[1] =
      if options.filename then fs.realpathSync(options.filename) else '.'

  # Clear the module cache.
  mainModule.moduleCache and= {}

  # Assign paths for node_modules loading
  mainModule.paths = require('module')._nodeModulePaths path.dirname options.filename

  # Compile.
  if (not isCoffeeFile mainModule.filename) or require.extensions
    mainModule._compile compile(code, options), mainModule.filename
  else
    mainModule._compile code, mainModule.filename

# Compile and evaluate a string of CoffeeScript (in a Node.js-like environment).
# The CoffeeScript REPL uses this to run the input.
exports.eval = (code, options = {}) ->
  return unless code = code.trim()
  Script = vm.Script
  if Script
    if options.sandbox?
      if options.sandbox instanceof Script.createContext().constructor
        sandbox = options.sandbox
      else
        sandbox = Script.createContext()
        sandbox[k] = v for own k, v of options.sandbox
      sandbox.global = sandbox.root = sandbox.GLOBAL = sandbox
    else
      sandbox = global
    sandbox.__filename = options.filename || 'eval'
    sandbox.__dirname  = path.dirname sandbox.__filename
    # define module/require only if they chose not to specify their own
    unless sandbox isnt global or sandbox.module or sandbox.require
      Module = require 'module'
      sandbox.module  = _module  = new Module(options.modulename || 'eval')
      sandbox.require = _require = (path) ->  Module._load path, _module, true
      _module.filename = sandbox.__filename
      _require[r] = require[r] for r in Object.getOwnPropertyNames require when r isnt 'paths'
      # use the same hack node currently uses for their own REPL
      _require.paths = _module.paths = Module._nodeModulePaths process.cwd()
      _require.resolve = (request) -> Module._resolveFilename request, _module
  o = {}
  o[k] = v for own k, v of options
  o.bare = on # ensure return value
  js = compile code, o
  if sandbox is global
    vm.runInThisContext js
  else
    vm.runInContext js, sandbox

# Instantiate a Lexer for our use here.
lexer = new Lexer

# The real Lexer produces a generic stream of tokens. This object provides a
# thin wrapper around it, compatible with the Jison API. We can then pass it
# directly as a "Jison lexer".
parser.lexer =
  lex: ->
    [tag, @yytext, @yylineno] = @tokens[@pos++] or ['']
    tag
  setInput: (@tokens) ->
    @pos = 0
  upcomingInput: ->
    ""

parser.yy = require './nodes'

# Export the iced runtime as 'iced'
exports.iced = iced.runtime
