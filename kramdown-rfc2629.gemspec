spec = Gem::Specification.new do |s|
  s.name = 'kramdown-rfc2629'
  s.version = '1.3.10'
  s.summary = "Kramdown extension for generating RFC 7749 XML."
  s.description = %{An RFC7749 (XML2RFC) generating backend for Thomas Leitner's
"kramdown" markdown parser.  Mostly useful for RFC writers.}
  s.add_dependency('kramdown', '~> 1.17.0')
  s.add_dependency('certified', '~> 1.0')
  s.files = Dir['lib/**/*.rb'] + %w(README.md LICENSE kramdown-rfc2629.gemspec bin/kdrfc bin/kramdown-rfc2629 bin/doilit bin/kramdown-rfc-extract-markdown data/kramdown-rfc2629.erb data/encoding-fallbacks.txt)
  s.require_path = 'lib'
  s.executables = ['kramdown-rfc2629', 'doilit', 'kramdown-rfc-extract-markdown', 'kdrfc']
  s.required_ruby_version = '>= 2.3.0'
  # s.requirements = 'wget'
  #  s.has_rdoc = true
  s.author = "Carsten Bormann"
  s.email = "cabo@tzi.org"
  s.homepage = "http://github.com/cabo/kramdown-rfc2629"
  s.license = 'MIT'
end
