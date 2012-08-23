isInt = (x) -> Math.round(x) == x

prop.group 'arb.int', ->
  prop 'is int',
       x: arb.int,
       -> isInt @x

  prop 'is at most size',
       size: arb.positive,
       ->
         x = arb.sized(@size, arb.int)()
         Math.abs(x) <= @size

prop.group 'arb.positive', ->
  prop 'is int',
       x: arb.positive,
       -> isInt @x

  prop 'is positive',
       x: arb.positive,
       -> @x >= 0

  prop 'is at most size',
       size: arb.positive,
       ->
         x = arb.sized(@size, arb.positive)()
         Math.abs(x) <= @size

prop 'arb.char is string',
     c: arb.char,
     -> typeof(@c) == "string"

prop 'arb.char is printable',
     c: arb.char,
     -> @c.charCodeAt(0) >= 20

prop 'arb.string is string',
     s: arb.string,
     -> typeof(@s) == "string"

prop.group 'array of ints', ->
  prop 'is array',
       a: arb.arrayOf(arb.int),
       -> @a instanceof Array

  prop 'contains ints'
       a: arb.arrayOf(arb.int),
       -> if @a[0] then isInt @a[0] else true

prop.group 'array of arrays', ->
  prop 'contains arrays',
       a: arb.arrayOf(arb.arrayOf(arb.int)),
       -> if @a[0] then @a[0] instanceof Array else true

prop.group 'sized array', ->
  prop 'length <= size',
       length: arb.positive,
       ->
         a = arb.sized(@length, arb.arrayOf(arb.int))()
         a.length <= @length

  prop 'subarrays at half length',
       length: arb.positive,
       ->
         a = arb.sized(@length,
                       arb.arrayOf(arb.arrayOf(arb.int)))()
         if a[0]
           a[0].length <= @length / 2
         else
           true

prop.group "arb.object", ->
  prop 'is an object',
       x: arb.object(a: arb.int, b: arb.char),
       -> typeof(@x) == 'object'

  prop 'is uses given generators',
       x: arb.object(a: arb.int, b: arb.char),
       -> isInt(@x.a) && typeof(@x.b) == 'string'

  prop 'is sizable',
       x: arb.sized(10, arb.object(a: arb.int, b: arb.char)),
       -> Math.abs(@x.a) <= 10

prop.group "arbitrarily called function", ->
  f = (x,y) -> x + y
  arbF = f.arbitrarily arb.int, arb.int

  prop 'calls function with values from given generators',
       x: arbF,
       -> isInt @x

  prop 'can be sized',
       x: arb.sized(10, arbF),
       -> Math.abs(@x) <= 20

