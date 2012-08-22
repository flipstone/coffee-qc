prop.group "outer", ->
  prop.group "inner 1", ->
    prop "foo",
         x: arb.int,
         -> @x == @x

  prop.group "inner 2", ->
    prop "bar",
         x: arb.int,
         -> @x == @x

