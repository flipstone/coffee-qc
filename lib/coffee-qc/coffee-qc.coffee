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

class LoadError
  constructor: (@name, @error) ->
  check: (options) ->
    options.console "#{@name} failed to load:"
    options.console "  #{@error}"
    options.console ""
    passed: false

GLOBAL.arb = {}
arb.sized = (size, generator) -> -> generator(size)
arb.int = (size = 1000) -> Math.round(Math.random() * size * 2) - size
arb.positive = (size = 1000) -> Math.round(Math.random() * size)

arb.charInRange = (min, max) ->
  int = Math.round(Math.random() * (max - min)) + min
  String.fromCharCode int

arb.char = -> arb.charInRange 32, 126
arb.alphaCharUpper = -> arb.charInRange 65, 90
arb.alphaCharLower =  -> arb.charInRange 97, 122
arb.alphaChar = -> if arb.boolean() then arb.alphaCharUpper() else arb.alphaCharLower()

arb.stringOf = (generator) -> (size) -> arb.arrayOf(generator)(size).join('')
arb.string = arb.stringOf arb.char
arb.alpha = arb.stringOf arb.alphaChar

arb.object = (example) ->
  (size) ->
    obj = {}
    obj[k] = v(size) for k,v of example
    obj

arb.arrayOf = (generator) ->
  (size = 100) ->
    length = Math.round(Math.random() * size)
    for i in [0...length]
      generator(Math.floor(size / 2))

arb.boolean = () -> Math.random() > 0.5

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

loadFile = (filepath) ->
  try
    require filepath.replace(".coffee","")
  catch error
    __props.push new LoadError(filepath, error)

loadDirectory = (path) ->
  files = walkdir.sync path
  for f in files
    stats = fs.statSync f
    if stats.isFile()
      loadFile f

loadFileOrDir = (path) ->
  stats = fs.statSync path

  if stats.isFile()
    loadFile path
  else
    loadDirectory path

loadProps = (filepath) ->
  __props = []

  loadFileOrDir filepath

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

