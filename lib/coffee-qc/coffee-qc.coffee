walkdir = require 'walkdir'
fs = require 'fs'

isObject = (obj) -> typeof(obj) == 'object' && !(obj instanceof Array)

inspectForFalsification = (obj, options = {}) ->
  indent = options.indent || 0
  indentString = (' ' for i in [0...indent]).join ''

  if isObject obj
    lines = for k,v of obj
      if isObject v
        nestedInspect = inspectForFalsification v, indent: indent + 2
        indentString + "#{k}:\n#{nestedInspect}"
      else
        indentString + "#{k}: #{v}"

    lines.join "\n"
  else
    indentString + obj.toString()


class Property
  constructor: (@name, @argSpec, @f) ->

  arbitraryContext: (size) ->
    ctx = {}

    for k,v of @argSpec
      ctx[k] = v(size)

    ctx

  check: (options) ->
    for n in [0..99]
      ctx = @arbitraryContext(n)
      if !@f.apply ctx
        options.console "#{@name}: failed after #{n} trials"
        options.console "  Falsified by:"

        options.console inspectForFalsification(ctx, indent: 4)
        options.console ""

        return {passed: false}

    passed: true


GLOBAL.arb =
  sized: (size, generator) -> -> generator(size)

  int: (size = 1000) -> Math.round(Math.random() * size * 2) - size
  positive: (size = 1000) -> Math.round(Math.random() * size)
  char: ->
    # 20..255 = printable char
    int = Math.round(Math.random() * 235) + 20
    String.fromCharCode int

  string: -> arb.arrayOf(arb.char)().join ''

  object: (example) ->
    (size) ->
      obj = {}
      obj[k] = v(size) for k,v of example
      obj

  arrayOf: (generator) ->
    (size = 100) ->
      length = Math.round(Math.random() * size)
      for i in [0...length]
        generator(Math.floor(size / 2))

Function.prototype.arbitrarily = (generators...) ->
  f = this
  (size) ->
    args = (g(size) for g in generators)
    f args...

Function.prototype.instanceArbitrarily = (generators...) ->
  f = this
  (size) ->
    args = (g(size) for g in generators)
    new f args...

GLOBAL.prop = (name, argSpec, f) ->
  __props.push new Property name, argSpec, f

GLOBAL.prop.group = (groupName, f) ->
  ungroupedProp = GLOBAL.prop

  try
    GLOBAL.prop = (name, args...) ->
      ungroupedProp "#{groupName} - #{name}", args...
    GLOBAL.prop.group = ungroupedProp.group

    f()

  finally
    GLOBAL.prop = ungroupedProp


__props = []

loadProps = (filepath) ->
  __props = []

  try
    files = walkdir.sync filepath
    for f in files
      stats = fs.statSync f
      if stats?.isFile()
        require f.replace(".coffee","")

  catch error
    require filepath

  props = __props
  __props = []
  props


exports.run = (options) ->
  props = loadProps options.filepath

  results = (p.check(options) for p in props)
  failures = (r for r in results when !r.passed)

  options.console "#{failures.length} Failures / #{props.length} Properties"

  passed: didAll results, 'passed'

didAll = (array, property) ->
  return false for a in array when !a[property]
  true

