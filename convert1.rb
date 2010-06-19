#!/opt/local/bin/ruby1.9
# this doesn't work with kramdown 0.8.0, it needs 0.9.0
$: << "/Users/cabo/big/kramdown/lib"
require 'kramdown'
require 'kramdown-rfc2629'
require 'yaml'

Encoding.default_external = "UTF-8" # wake up, smell the coffee

options = {numeric_entities: true, input: 'RFC2629Kramdown'}
input = "{::nomarkdown}\n#{ARGF.read}\n{:/nomarkdown}\n"
doc = Kramdown::Document.new(input, options)
$stderr.puts doc.warnings.to_yaml unless doc.warnings.empty?
puts doc.to_rfc2629
