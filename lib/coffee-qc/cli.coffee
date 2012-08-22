qc = require './coffee-qc'
path = require 'path'

fullPath = (file) -> path.join(process.cwd(), file)

results = qc.run
  filepath: fullPath process.argv[2]
  console: console.log

if !results.passed
  process.exit 1

