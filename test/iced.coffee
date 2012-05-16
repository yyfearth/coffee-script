
delay = (cb, i) ->
   i = i || 3
   setTimeout cb, i

atest "basic iced waiting", (cb) ->
   i = 1
   await delay defer()
   i++
   cb(i is 2, {})

foo = (i, cb) ->
  await delay(defer(), i)
  cb(i)

atest "basic iced waiting", (cb) ->
   i = 1
   await delay defer()
   i++
   cb(i is 2, {})

atest "basic iced trigger values", (cb) ->
   i = 10
   await foo(i, defer j)
   cb(i is j, {})

atest "basic iced set structs", (cb) ->
   field = "yo"
   i = 10
   obj = { cat : { dog : 0 } }
   await
     foo(i, defer obj.cat[field])
     field = "bar" # change the field to make sure that we captured "yo"
   cb(obj.cat.yo is i, {})

multi = (cb, arr) ->
  await delay defer()
  cb.apply(null, arr)

atest "defer splats", (cb) ->
  v = [ 1, 2, 3, 4]
  obj = { x : 0 }
  await multi(defer(obj.x, out...), v)
  out.unshift obj.x
  ok = true
  for i in [0..v.length-1]
    ok = false if v[i] != out[i]
  cb(ok, {})

atest "continue / break test" , (cb) ->
  tot = 0
  for i in [0..100]
    await delay defer()
    continue if i is 3
    tot += i
    break if i is 10
  cb(tot is 52, {})

atest "for k,v of obj testing", (cb) ->
  obj = { the : "quick", brown : "fox", jumped : "over" }
  s = ""
  for k,v of obj
    await delay defer()
    s += k + " " + v + " "
  cb( s is "the quick brown fox jumped over ", {} )

atest "for k,v in arr testing", (cb) ->
  obj = [ "the", "quick", "brown" ]
  s = ""
  for v,i in obj
    await delay defer()
    s += v + " " + i + " "
  cb( s is "the 0 quick 1 brown 2 ", {} )

atest "switch-a-roos", (cb) ->
  res = 0
  for i in [0..4]
    await delay defer()
    switch i
      when 0 then res += 1
      when 1
        await delay defer()
        res += 20
      when 2
        await delay defer()
        if false
          res += 100000
        else
          await delay defer()
          res += 300
      else
        res += i*1000
    res += 10000 if i is 2
  cb( res is 17321, {} )


atest "parallel awaits with classes", (cb) ->
  class MyClass
    constructor: ->
      @val = 0
    increment: (wait, i, cb) ->
      await setTimeout(defer(),wait)
      @val += i
      await setTimeout(defer(),wait)
      @val += i
      cb()
    getVal: -> @val

  obj = new MyClass()
  await
    obj.increment 10, 1, defer()
    obj.increment 20, 2, defer()
    obj.increment 30, 4, defer()
  v = obj.getVal()
  cb(v is 14, {})

atest "loop construct", (cb) ->
  i = 0
  loop
    await delay defer()
    i += 1
    await delay defer()
    break if i is 10
    await delay defer()
  cb(i is 10, {})

atest "simple autocb operations", (cb) ->
  b = false
  foo = (autocb) ->
    await delay defer()
    true
  await foo defer b
  cb(b, {})

atest "AT variable works in an await (1)", (cb) ->
  class MyClass
    constructor : ->
      @flag = false
    chill : (autocb) ->
      await delay defer()
    run : (autocb) ->
      await @chill defer()
      @flag = true
    getFlag : -> @flag
  o = new MyClass
  await o.run defer()
  cb(o.getFlag(), {})

atest "more advanced autocb test", (cb) ->
  bar = -> "yoyo"
  foo = (val, autocb) ->
    await delay defer()
    if val is 0 then [1,2,3]
    else if val is 1 then { a : 10 }
    else if val is 2 then bar()
    else 33
  oks = 0
  await foo 0, defer x
  oks++ if x[2] is 3
  await foo 1, defer x
  oks++ if x.a is 10
  await foo 2, defer x
  oks++ if x is "yoyo"
  await foo 100, defer x
  oks++ if x is 33
  cb(oks is 4, {})

atest "test of autocb in a simple function", (cb) ->
  simple = (autocb) ->
    await delay defer()
  ok = false
  await simple defer()
  ok = true
  cb(ok,{})

atest "test nested serial/parallel", (cb) ->
  slots = []
  await
    for i in [0..10]
      ( (j, autocb) ->
        await delay defer(), 5 * Math.random()
        await delay defer(), 4 * Math.random()
        slots[j] = true
      )(i, defer())
  ok = true
  for i in [0..10]
    ok = false unless slots[i]
  cb(ok, {})

atest "loops respect autocbs", (cb) ->
  ok = false
  bar = (autocb) ->
    for i in [0..10]
      await delay defer()
      ok = true
  await bar defer()
  cb(ok, {})

atest "test scoping", (cb) ->
  class MyClass
    constructor : -> @val = 0
    run : (autocb) ->
      @val++
      await delay defer()
      @val++
      await
        class Inner
          chill : (autocb) ->
            await delay defer()
            @val = 0
        i = new Inner
        i.chill defer()
      @val++
      await delay defer()
      @val++
      await
        ( (autocb) ->
          class Inner
            chill : (autocb) ->
              await delay defer()
              @val = 0
          i = new Inner
          await i.chill defer()
        )(defer())
      ++@val
    getVal : -> @val
  o = new MyClass
  await o.run defer(v)
  cb(v is 5, {})

atest "AT variable works in an await (2)", (cb) ->
  class MyClass
    constructor : -> @val = 0
    inc : -> @val++
    chill : (autocb) -> await delay defer()
    run : (autocb) ->
      await @chill defer()
      for i in [0..9]
        await @chill defer()
        @inc()
    getVal : -> @val
  o = new MyClass
  await o.run defer()
  cb(o.getVal() is 10, {})

atest "another autocb gotcha", (cb) ->
  bar = (autocb) ->
    await delay defer() if yes
  ok = false
  await bar defer()
  ok = true
  cb(ok, {})

atest "fat arrow versus iced", (cb) ->
  class Foo
    constructor : ->
      @bindings = {}

    addHandler : (key,cb) ->
      @bindings[key] = cb

    useHandler : (key, args...) ->
      @bindings[key](args...)

    delay : (autocb) ->
      await delay defer()

    addHandlers : ->
      @addHandler "sleep1", (cb) =>
        await delay defer()
        await @delay defer()
        cb(true)
      @addHandler "sleep2", (cb) =>
        await @delay defer()
        await delay defer()
        cb(true)

  ok1 = ok2 = false
  f = new Foo()
  f.addHandlers()
  await f.useHandler "sleep1", defer(ok1)
  await f.useHandler "sleep2", defer(ok2)
  cb(ok1 and ok2, {})

atest "nested loops", (cb) ->
  val = 0
  for i in [0..9]
    await delay(defer(),1)
    for j in [0..9]
      await delay(defer(),1)
      val++
  cb(val is 100, {})

atest "empty autocb", (cb) ->
  bar = (autocb) ->
  await bar defer()
  cb(true, {})

atest "more autocb (false)", (cb) ->
  bar = (autocb) ->
    if false
      console.log "not reached"
  await bar defer()
  cb(true, {})

atest "more autocb (true)", (cb) ->
  bar = (autocb) ->
    if true
      10
  await bar defer()
  cb(true, {})

atest "more autocb (true & false)", (cb) ->
  bar = (autocb) ->
    if false
      10
    else
      if false
        11
  await bar defer()
  cb(true, {})

atest "more autocb (while)", (cb) ->
  bar = (autocb) ->
    while false
      10
  await bar defer()
  cb(true, {})

atest "more autocb (comments)", (cb) ->
  bar = (autocb) ->
    ###
    blah blah blah
    ###
  await bar defer()
  cb(true, {})

atest "until", (cb) ->
  i = 10
  out = 0
  until i is 0
    await delay defer()
    out += i--
  cb(out is 55, {})

atest 'expressions -- simple assignment', (cb) ->
  adder = (x, cb) ->
    await delay defer()
    cb(x+1)
  ret = await adder 5, defer _
  cb(ret is 6, {})

atest 'expressions -- simple, but recursive', (cb) ->
  y = if true
    await delay defer()
    10
  cb(y is 10, {})

atest 'expressions -- simple, but recursive (2)', (cb) ->
  adder = (x, cb) ->
    await delay defer()
    cb(x+1)
  y = if true
    x = await adder 4, defer _
    ++x
  cb(y is 6, {})

atest 'expressions -- pass value of tail calls', (cb) ->
  adder = (x, cb) ->
    await delay defer()
    cb(x+1)
  y = if true
    await adder 5, defer _
  cb(y is 6, {})

atest 'expressions -- addition (1)', (cb) ->
  slowAdd = (a, b, autocb) ->
    await delay defer()
    a+b
  y = 30 + (await slowAdd 30, 40, defer _)
  cb(y is 100, {})


atest 'expressions -- addition (2)', (cb) ->
  slowAdd = (a, b, autocb) ->
    await delay defer()
    a+b
  y = (await slowAdd 10, 20, defer _) + (await slowAdd 30, 40, defer _)
  cb(y is 100, {})

atest 'expressions - chaining', (cb) ->
  id = "image data"
  class Img
    render : -> id
  loadImage = (n, cb) ->
    await delay defer()
    cb new Img
  x = (await loadImage "test.png", defer _).render()
  cb(x is id, {})

atest 'expressions - call args', (cb) ->
  slowAdd = (a,b,autocb) ->
    await delay defer()
    a+b
  x = await slowAdd 3, (await slowAdd 3, 4, defer _), defer _
  cb(x is 10, {})

atest 'expressions - call args (2)', (cb) ->
  slowAdd = (a,b,autocb) ->
    await delay defer()
    a+b
  x = await slowAdd (await slowAdd 1, 2, defer _), (await slowAdd 3, 4, defer _), defer _
  cb(x is 10, {})

atest 'arrays and objects', (cb) ->
  id = "image data"
  loadImage = (n, cb) ->
    await delay defer()
    cb id
  arr = [
    (await loadImage "file.jpg", defer _),
    "another value" ]
  obj =
    i : (await loadImage "file.jpg", defer _)
    v : "another value"
  cb(arr[0] is id and obj.i is id, {})

atest 'arrays 2', (cb) ->
  parrot = (n, cb) ->
    await delay defer()
    cb n
  arr = [
    (await parrot 1, defer _),
    [ (await parrot 2, defer _),
      (await parrot 3, defer _) ],
    (await parrot 4, defer _) ]
  cb(arr[0] + arr[1][0] + arr[1][1] + arr[2] is 10, {})

atest 'nesting', (cb) ->
  id = "image data"
  loadImage = (n, cb) ->
    await delay defer()
    cb id
  render = (x) -> x + x
  y = render(await loadImage "test.png", defer _)
  cb(y is (id + id), {})

atest 'expressions + loops', (cb) ->
  parrot = (n, cb) ->
    await delay defer()
    cb n
  x = for i in [0..9]
    await parrot i, defer _
  y = while i--
    await parrot i, defer _
  z = (v + y[i] for v,i in x)
  ok = true
  for v in z
    ok = false unless v is 9
  cb(ok, {})

atest 'expressions + loops', (cb) ->
  eat = (item, cb) ->
    await delay defer()
    cb item.length
  lunch = ((await eat food, defer _) for food in ['toast', 'wine', 'pea'])
  ok = (lunch[0] is 5 and lunch[1] is 4 and lunch[2] is 3)
  cb(ok, {})

atest 'expressions + ops + if', (cb) ->
  parrot = (n, cb) ->
    await delay defer()
    cb n
  y = if true
    (await parrot 10, defer _) + 1
  cb(y is 11, {})

atest 'expressions + ops + if (2)', (cb) ->
  parrot = (n, cb) ->
    await delay defer()
    cb n
  y = if true
    (await parrot 10, defer _) + 1 + (await parrot 12, defer _)
  cb(y is 23, {})

atest 'expressions + ops + if (3)', (cb) ->
  parrot = (n, cb) ->
    await delay defer()
    cb n
  y = if true
    (await parrot 10, defer _) + 1
    3
  cb(y is 3, {})

atest 'super with no args', (cb) ->
  class P
    constructor: ->
      @x = 10
  class A extends P
    constructor : ->
      super
    foo : (cb) ->
      await delay defer()
      cb()
  a = new A
  await a.foo defer()
  cb(a.x is 10, {})

atest 'nested for .. of .. loops', (cb) ->
  x =
    christian:
      age: 36
      last: "rudder"
    max:
      age: 34
      last: "krohn"

  tot = 0
  for first, info of x
    tot += info.age
    for k,v of info
      await delay defer()
      tot++
  cb(tot is 74, {})

atest 'for + return + autocb', (cb) ->
  bar = (autocb) ->
    await delay defer()
    (i for i in [0..10])
  await bar defer v
  cb(v[3] is 3, {})

atest 'for + return + autocb (part 2)', (cb) ->
  bar = (autocb) ->
    await delay defer()
    x = (i for i in [0..10])
    [10..20]
  await bar defer v
  cb(v[3] is 13, {})

atest "for + guards", (cb) ->
  v = for i in [0..10] when i % 2 is 0
    await delay defer()
    i
  cb(v[3] is 6, {})

atest "while + guards", (cb) ->
  i = 0
  v = while (x = i++) < 10 when x % 2 is 0
    await delay defer()
    x
  cb(v[3] is 6, {})

atest "nested loops + inner break", (cb) ->
  i = 0
  while i < 10
    await delay defer()
    j = 0
    while j < 10
      if j == 5
        break
      j++
    i++
  res = j*i
  cb(res is 50, {})

atest "defer and object assignment", (cb) ->
  baz = (cb) ->
    await delay defer()
    cb { a : 1, b : 2, c : 3}
  out = []
  await
    for i in [0..2]
      switch i
        when 0 then baz defer { c : out[i] }
        when 1 then baz defer { b : out[i] }
        when 2 then baz defer { a : out[i] }
  cb( out[0] is 3 and out[1] is 2 and out[2] is 1, {} )

atest 'defer + arguments', (cb) ->
  bar = (i, cb) ->
    await delay defer()
    arguments[1](arguments[0])
  await bar 10, defer x
  cb(10 is x, {})

# See comment in declaredVariables in src/scope.coffee for
# an explanation of the fix to this bug.
atest 'autocb + wait + scoping problems', (cb) ->
  fun1 = (autocb) ->
    await delay defer()
    for i in [0..10]
      await delay defer()
      1
  fun2 = (autocb) ->
    await delay defer()
    for j in [0..2]
      await delay defer()
      2
  await
    fun1 defer x
    fun2 defer y
  cb(x[0] is 1 and y[0] is 2, {})


atest 'for in by + await', (cb) ->
  res = []
  for i in [0..10] by 3
    await delay defer()
    res.push i
  cb(res.length is 4 and res[3] is 9, {})


atest 'super after await', (cb) ->
  class A
    constructor : ->
      @_i = 0
    foo : (cb) ->
      await delay defer()
      @_i += 1
      cb()
  class B extends A
    constructor : ->
      super
    foo : (cb) ->
      await delay defer()
      await delay defer()
      @_i += 2
      super cb
  b = new B()
  await b.foo defer()
  cb(b._i is 3, {})
