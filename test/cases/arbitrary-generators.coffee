prop 'arb.int',
     x: arb.int,
     -> Math.round(@x) == @x

prop 'arb.char is string',
     c: arb.char,
     -> typeof(@c) == "string"

prop 'arb.char is printable',
     c: arb.char,
     -> @c.charCodeAt(0) >= 20

prop 'arb.string is string',
     s: arb.string,
     -> typeof(@s) == "string"

