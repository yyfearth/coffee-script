
# =======================================================================
# Compile Time!
#
exports.transform = (x) ->
  x.icedTransform()

exports.const = C =
  k : "__iced_k"
  param : "__iced_p_"
  ns: "iced"
  Deferrals : "Deferrals"
  deferrals : "__iced_deferrals"
  fulfill : "_fulfill"
  b_while : "_break"
  t_while : "_while"
  c_while : "_continue"
  n_while : "_next"
  n_arg   : "__iced_next_arg"
  defer_method : "defer"
  slot : "__slot"
  assign_fn : "assign_fn"
  runtime : "icedrun"
  autocb : "autocb"
  retslot : "ret"
  trace : "__iced_trace"
  passed_deferral : "__iced_passed_deferral"
  findDeferral : "findDeferral"
  lineno : "lineno"
  parent : "parent"
  filename : "filename"
  funcname : "funcname"
  catchExceptions : 'catchExceptions'
  runtime_modes : [ "node", "inline", "window", "none" ]

#=======================================================================
# runtime

makeDeferReturn = (obj, defer_args, id, trace_template) ->
  
  trace = {}
  for k,v of trace_template
    trace[k] = v
  trace[C.lineno] = defer_args?[C.lineno]
  
  ret = (inner_args...) ->
    defer_args?.assign_fn?.apply(null, inner_args)
    obj._fulfill id, trace

  ret[C.trace] = trace
    
  ret

#-----------------------------------------------------------------------
# 
# Tick Counter --
#    count off every mod processor ticks
# 
__c = 0

tickCounter = (mod) ->
  __c++
  if (__c % mod) == 0
    __c = 0
    true
  else
    false

__active_trace = null

#-----------------------------------------------------------------------
# Deferrals
#
#   A collection of Deferrals; this is a better version than the one
#   that's inline; it allows for iced tracing
#

class Deferrals

  constructor: (k, @trace) ->
    @continuation = k
    @count = 1
    @ret = null

  _call : (trace) ->
    __active_trace = trace
    @continuation @ret

  _fulfill : (id, trace) ->
    if --@count == 0
      if tickCounter 500
        process.nextTick (=> @_call trace)
      else
        @_call trace

  defer : (args) ->
    @count++
    self = this
    return makeDeferReturn self, args, null, @trace

#=======================================================================

findDeferral = (args) ->
  for a in args
    return a if a?[C.trace]
  return null

#=======================================================================

class Rendezvous
  constructor: ->
    @completed = []
    @waiters = []
    @defer_id = 0
    # This is a hack to work with the desugaring of
    # 'defer' output by the coffee compiler.
    @[C.deferrals] = this

  #-----------------------------------------
    
  class RvId
    constructor: (@rv,@id)->
    defer: (defer_args) ->
      @rv._deferWithId @id, defer_args

  #-----------------------------------------
  # 
  # The public interface has 3 methods --- wait, defer and id
  wait: (cb) ->
    if @completed.length
      x = @completed.shift()
      cb(x)
    else
      @waiters.push cb

  #-----------------------------------------

  defer: (defer_args) ->
    id = @defer_id++
    @deferWithId id, defer_args

  #-----------------------------------------
  
  id: (i) ->
    ret = {}
    ret[C.deferrals] = new RvId(this, i)
    ret
  
  #-----------------------------------------

  _fulfill: (id, trace) ->
    if @waiters.length
      cb = @waiters.shift()
      cb(id)
    else
      @completed.push id

  #-----------------------------------------
  
  _deferWithId: (id, defer_args) ->
    @count++
    makeDeferReturn this, defer_args, id, {}

#=======================================================================

stackWalk = (cb) ->
  ret = []
  tr = if cb then cb[C.trace] else __active_trace
  while tr
    fn = tr[C.funcname] || "<anonymous>"
    line = "   at #{fn} (#{tr[C.filename]}:#{tr[C.lineno] + 1})"
    ret.push line
    tr = tr?[C.parent]?[C.trace]
  ret
 
#=======================================================================

exceptionHandler = (err) ->
  console.log err.stack
  stack = stackWalk()
  if stack.length
    console.log "Iced 'stack' trace (w/ real line numbers):"
    console.log stack.join "\n"
 
#=======================================================================

# Catch all uncaught exceptions with the tamejs exception handler.
# As mentioned here:
#
#    http://debuggable.com/posts/node-js-dealing-with-uncaught-exceptions:4c933d54-1428-443c-928d-4e1ecbdd56cb 
# 
# It's good idea to kill the service at this point, since state
# is probably horked. See his examples for more explanations.
# 
catchExceptions = () ->
  process.on 'uncaughtException', (err) ->
  	exceptionHandler err
  	process.exit 1

#=======================================================================

exports.runtime = { Deferrals, Rendezvous, findDeferral, stackWalk,
  exceptionHandler, catchExceptions }

#=======================================================================
