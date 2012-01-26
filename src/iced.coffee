
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

#=======================================================================
# runtime

makeDeferReturn = (obj, defer_args, id, trace_template) ->
  ret = (inner_args...) ->
    defer_args?.assign_fn?.apply(null, inner_args)
    obj._fulfill id

  if defer_args
    trace = {}
    trace[C.lineno] = defer_args[C.lineno]
    for k in [ C.parent, C.filename ]
      trace[k] = trace_template[k]
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

  _call : ->
    @continuation @ret

  _fulfill : ->
    if --@count == 0
      if tickCounter 500
        process.nextTick (=> @_call())
      else
        @_call()

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

  _fulfill: (id) ->
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

exports.runtime = { Deferrals, Rendezvous, findDeferral }

#=======================================================================
