# minify js with uglify-js add by wilson
{parser, uglify} = require 'uglify-js'
exports.minify = (code, opt) ->
  if not opt or opt is true
    uglify.split_lines (uglify.gen_code (uglify.ast_squeeze uglify.ast_mangle parser.parse code), ascii_only: on, inline_script: on), 32768 # 32 * 1024
  else
    opt.max_line_length ?= opt.max_line_len ? 32768 # 32 * 1024
    opt.lift_variables = opt.lift_variables or opt.lift_vars or false
    opt.ascii_only ?= not opt.allow_non_ascii # default yes
    opt.inline_script ?= on
    ast = parser.parse code, opt.strict_semicolons # parse code and get the initial AST
    ast = uglify.ast_lift_variables ast if opt.lift_variables # merge var, discard unused arg, var, inner func
    ast = uglify.ast_mangle ast, opt unless opt.no_mangle # get a new AST with mangled names
    ast = uglify.ast_squeeze ast, opt unless opt.no_squeeze # get an AST with compression optimizations
    ast = uglify.gen_code ast, opt # compressed code here
    ast = uglify.split_lines ast, opt.max_line_length if opt.max_line_length > 0
    ast
