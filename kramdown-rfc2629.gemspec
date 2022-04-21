spec = Gem::Specification.new do |s|
  s.name = 'kramdown-rfc2629'
  s.version = '1.6.7'
  s.summary = "Kramdown extension for generating RFCXML (RFC 799x)."
  s.description = %{An RFCXML (RFC 799x) generating backend for Thomas Leitner's
"kramdown" markdown parser.  Mostly useful for RFC writers.}
  s.add_dependency('kramdown', '~> 2.3.0')
  s.add_dependency('kramdown-parser-gfm', '~> 1.1')
  s.add_dependency('certified', '~> 1.0')
  s.add_dependency('json_pure', '~> 2.0')
  s.files = Dir['lib/**/*.rb'] + %w(README.md LICENSE kramdown-rfc2629.gemspec bin/kdrfc bin/kramdown-rfc bin/kramdown-rfc2629 bin/doilit bin/kramdown-rfc-extract-markdown data/kramdown-rfc2629.erb data/encoding-fallbacks.txt data/math.json bin/kramdown-rfc-cache-subseries-bibxml bin/kramdown-rfc-autolink-iref-cleanup.rb bin/de-gfm)
  s.require_path = 'lib'
  s.executables = ['kramdown-rfc', 'kramdown-rfc2629', 'doilit', 'kramdown-rfc-extract-markdown',
                   'kdrfc', 'kramdown-rfc-cache-i-d-bibxml',
                   'kramdown-rfc-cache-subseries-bibxml', 'de-gfm']
  s.required_ruby_version = '>= 2.3.0'
  # s.requirements = 'wget'
  #  s.has_rdoc = true
  s.author = "Carsten Bormann"
  s.email = "cabo@tzi.org"
  s.homepage = "http://github.com/cabo/kramdown-rfc"
  s.license = 'MIT'
end
