#!/opt/local/bin/ruby1.9
# this version is adapted to kramdown 0.11.0
gem 'kramdown', '= 0.11.0'
require 'kramdown'
require_relative 'kramdown-rfc2629'
require 'yaml'

Encoding.default_external = "UTF-8" # wake up, smell the coffee

options = {input: 'RFC2629Kramdown'}
input = ARGF.read.gsub(/\{::include\s+(.*?)\}/) {
  File.read($1).chomp
}
input = "{::nomarkdown}\n#{input}\n{:/nomarkdown}\n"
doc = Kramdown::Document.new(input, options)
$stderr.puts doc.warnings.to_yaml unless doc.warnings.empty?
puts doc.to_rfc2629
