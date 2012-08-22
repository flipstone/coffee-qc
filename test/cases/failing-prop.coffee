prop 'all integers are even',
     x: arb.int,
     -> (@x % 2) == 0
