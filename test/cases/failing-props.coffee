prop 'a + b == b + a',
     a: arb.int, b: arb.int,
     -> @a + @b == @b + @a

prop 'a / b == b / a',
     a: arb.int, b: arb.int,
     -> @a / @b == @b / @a

prop 'a * b == b * a',
     a: arb.int, b: arb.int,
     -> @a * @b == @b * @a

