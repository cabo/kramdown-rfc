#!/usr/bin/env ruby

# xml2rfc/trunk/cli/xml2rfc/data/v3.rnc

v3 = File.read("v3.rnc")
studly = {}
sc = v3.scan(/attribute [A-Za-z]*[A-Z][A-Za-z]*/).each do |s|
  _, an = s.split(" ")
  studly[an] = true
end

puts studly.keys.sort
