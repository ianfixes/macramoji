fs    = require 'fs'
jison = require 'jison'
path  = require 'path'

bnfFile = path.join __dirname, '..', 'data', 'extensimoji.jison'
bnf = fs.readFileSync bnfFile, 'utf8'
parser = new jison.Parser(bnf)

module.exports = parser
