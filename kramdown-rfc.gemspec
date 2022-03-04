spec = Gem::Specification.new do |s|
  s.name = 'kramdown-rfc'
  s.version = '1.6.3'
  s.summary = "Kramdown extension for generating RFCXML (RFC 799x)."
  s.description = %{An RFCXML (RFC 799x) generating backend for Thomas Leitner's
"kramdown" markdown parser.  Mostly useful for RFC writers.}
  s.add_dependency('kramdown-rfc2629', s.version)
  s.author = "Carsten Bormann"
  s.email = "cabo@tzi.org"
  s.homepage = "http://github.com/cabo/kramdown-rfc2629"
  s.license = 'MIT'
end
