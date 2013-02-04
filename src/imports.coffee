# imports component by wilson

fs               = require 'fs'
path             = require 'path'

exports.imports = (code, options = {}) ->
  regex = options.regex or /^\s*import\s+(['"])(.+)\1[;\s]*$/
  regex.pos = options.regex_pos or 2
  regex_g = new RegExp regex.source, 'gm'
  return code unless regex.test
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
  # return
  do parse = (code, filename) ->
    code.replace regex_g, (match) ->
      match = match.match regex
      dir = if filename then path.dirname fs.realpathSync filename else cwd
      _filename = f = path.resolve dir, match[regex.pos]
      unless chk_file _filename
        _filename = null
        exts = ['.coffee', '.js']
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
      import_code = "`#{import_code.replace /`/g, '\\x60'}`" if is_js isnt _is_js # if coffee import js
      #console.log 'import', _filename, import_code
      rmk = if /\.js$/.test filename then "/* imported #{_filename} */" else "### imported #{_filename} ###"
      "#{rmk}\n#{import_code}\n\n"
# end of import
