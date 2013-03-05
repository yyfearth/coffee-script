vm = require 'vm'
nodeREPL = require 'repl'
CoffeeScript = require './coffee-script'
{merge} = require './helpers'

replDefaults =
  prompt: 'coffee> ',
  eval: (input, context, filename, cb) ->
    # XXX: multiline hack
    input = input.replace /\uFF00/g, '\n'
    # strip single-line comments
    input = input.replace /(^|[\r\n]+)(\s*)##?(?:[^#\r\n][^\r\n]*|)($|[\r\n])/, '$1$2$3'
    # empty command
    return cb null if /^(\s*|\(\s*\))$/.test input
    # TODO: fix #1829: pass in-scope vars and avoid accidentally shadowing them by omitting those declarations
    try
      js = CoffeeScript.compile "_=(#{input}\n)", {filename, bare: yes}
      cb null, vm.runInContext(js, context, filename)
    catch err
      cb err

addMultilineHandler = (repl) ->
  {rli, inputStream, outputStream} = repl

  multiline =
    enabled: off
    initialPrompt: repl.prompt.replace(/^[^> ]*/, (x) -> x.replace /./g, '-')
    prompt: repl.prompt.replace(/^[^> ]*>?/, (x) -> x.replace /./g, '.')
    buffer: ''

  # Proxy node's line listener
  nodeLineListener = rli.listeners('line')[0]
  rli.removeListener 'line', nodeLineListener
  rli.on 'line', (cmd) ->
    if multiline.enabled
      multiline.buffer += "#{cmd}\n"
      rli.setPrompt multiline.prompt
      rli.prompt true
    else
      nodeLineListener cmd
    return

  # Handle Ctrl-v
  inputStream.on 'keypress', (char, key) ->
    return unless key and key.ctrl and not key.meta and not key.shift and key.name is 'v'
    if multiline.enabled
      # allow arbitrarily switching between modes any time before multiple lines are entered
      unless multiline.buffer.match /\n/
        multiline.enabled = not multiline.enabled
        rli.setPrompt repl.prompt
        rli.prompt true
        return
      # no-op unless the current line is empty
      return if rli.line? and not rli.line.match /^\s*$/
      # eval, print, loop
      multiline.enabled = not multiline.enabled
      rli.line = ''
      rli.cursor = 0
      rli.output.cursorTo 0
      rli.output.clearLine 1
      # XXX: multiline hack
      multiline.buffer = multiline.buffer.replace /\n/g, '\uFF00'
      rli.emit 'line', multiline.buffer
      multiline.buffer = ''
    else
      multiline.enabled = not multiline.enabled
      rli.setPrompt multiline.initialPrompt
      rli.prompt true
    return

module.exports =
  start: (opts = {}) ->
    opts = merge replDefaults, opts
    repl = nodeREPL.start opts
    repl.on 'exit', -> repl.outputStream.write '\n'
    addMultilineHandler repl
    repl
