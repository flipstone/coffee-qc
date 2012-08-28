qc = require '../lib/coffee-qc/coffee-qc'

path = require 'path'
cwd = process.cwd()

fullPath = (file) -> path.join(cwd, 'test', 'cases', file)

clearTestCasesFromCache = ->
  for k,v of require.cache
    if /test\/cases/.test k
      delete require.cache[k]

newConsole = ->
  log = (s) => log.output += "#{s}\n"
  log.output = ""
  log

assertPass = (file) ->
  try
    clearTestCasesFromCache()
    result = qc.run
      filepath: fullPath file
      console: newConsole()

    if result.passed
      console.log "#{file}: expected passing - check"
    else
      console.log "#{file}: expected passing - FAIL"
      process.exit 1
  catch error
    console.log "#{file}: expected passing - #{error}"
    process.exit 2

assertFail = (file) ->
  try
    clearTestCasesFromCache()
    result = qc.run
      filepath: fullPath file
      console: newConsole()

    if !result.passed
      console.log "#{file}: expected failing - check"
    else
      console.log "#{file}: expected failing - PASSED UNEXPECTEDLY"
      process.exit 1
  catch error
    console.log "#{file}: expected failing - #{error}"
    process.exit 2

outputMatches = (actual, expected) ->
  actualLines = actual.split("\n")
  expectedLines = expected.split("\n")

  return false if expectedLines.length != actualLines.length

  for i in [0...actualLines.length]
    return false unless new RegExp(expectedLines[i]).test(actualLines[i])

  true


assertOutput = (file, expected) ->
  try
    clearTestCasesFromCache()
    testConsole = newConsole()
    result = qc.run
      filepath: fullPath file
      console: testConsole

    if outputMatches testConsole.output, expected
      console.log "#{file}: checking output - check"
    else
      console.log "#{file}: checking output - FAILED"
      console.log ""
      console.log "Expected"
      console.log "--------"
      console.log expected
      console.log "--------"
      console.log "Actual"
      console.log "------"
      console.log testConsole.output
      console.log "------"
      process.exit 1

  catch error
    console.log "#{file}: checking output - #{error}"
    process.exit 2


assertPass 'passing-prop.coffee'

assertPass 'passing-props.coffee'
assertOutput 'passing-props.coffee', """
                                     0 Failures / 2 Properties

                                     """

assertPass 'passing-group.coffee'
assertOutput 'passing-group.coffee', """
                                     0 Failures / 2 Properties

                                     """

assertPass 'nested-group.coffee'
assertPass 'passing-dir'
assertOutput 'passing-dir', """
                            0 Failures / 2 Properties

                            """

assertOutput 'nested-dir', """
                           0 Failures / 2 Properties

                           """

assertFail 'failing-prop.coffee'
assertOutput 'failing-props.coffee', """
                                     a / b == b / a: failed after \\d+ trials
                                       Falsified by:
                                         a: -?\\d+
                                         b: -?\\d+

                                     1 Failures / 3 Properties

                                     """


assertFail 'failing-group.coffee'
assertOutput 'failing-object.coffee', """
                                      bad object: failed after \\d+ trials
                                        Falsified by:
                                          a:
                                            x: -?\\d+
                                            y: -?\\d+

                                      1 Failures / 1 Properties

                                      """

assertPass 'arbitrary-generators.coffee'

assertFail 'syntax-error.coffee'
assertOutput 'syntax-error.coffee', """
                                    .*syntax-error.coffee failed to load:
                                      ReferenceError: foo is not defined

                                    1 Failures / 1 Properties

                                    """

assertFail 'nested-syntax'
assertOutput 'nested-syntax', """
                             .*nested-syntax/error.coffee failed to load:
                               ReferenceError: foo is not defined

                             1 Failures / 1 Properties

                             """


