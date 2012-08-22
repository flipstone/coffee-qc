prop.group "Group", ->
  prop "ints are even or odd",
       x: arb.int,
       ->
         mod = Math.abs(@x) % 2
         mod == 0 || mod == 1

  prop "x*1 == x",
       x: arb.int,
       -> @x * 1 == @x
