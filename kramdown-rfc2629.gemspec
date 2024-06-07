spec = Gem::Specification.new do |s|
  s.name = 'kramdown-rfc2629'
  s.version = '1.7.15'
  s.summary = "Kramdown extension for generating RFCXML (RFC 799x)."
  s.description = %{An RFCXML (RFC 799x) generating backend for Thomas Leitner's
"kramdown" markdown parser.  Mostly useful for RFC writers.}
  s.add_dependency('kramdown', '~> 2.4.0')
  s.add_dependency('kramdown-parser-gfm', '~> 1.1')
  s.add_dependency('certified', '~> 1.0')
  s.add_dependency('json_pure', '~> 2.0')
  s.add_dependency('unicode-name', '~> 1.0')
  s.add_dependency('unicode-blocks', '~> 1.0')
  s.add_dependency('unicode-scripts', '~> 1.0')
  s.add_dependency('net-http-persistent', '~> 4.0')
  s.add_dependency('differ', '~> 0.1')
  s.add_dependency('base64', '>= 0.1')
  s.add_dependency('rexml', '<= 3.2.6') # emergency fix; newer REXML is no longer pure ruby (requires strscan)
  s.files = Dir['lib/**/*.rb'] + %w(README.md LICENSE kramdown-rfc2629.gemspec bin/kdrfc bin/kramdown-rfc bin/kramdown-rfc2629 bin/doilit bin/echars bin/kramdown-rfc-extract-markdown bin/kramdown-rfc-extract-sourcecode bin/kramdown-rfc-lsr data/kramdown-rfc2629.erb data/encoding-fallbacks.txt data/math.json bin/kramdown-rfc-cache-subseries-bibxml bin/kramdown-rfc-autolink-iref-cleanup bin/de-gfm bin/kramdown-rfc-clean-svg-ids)
  s.require_path = 'lib'
  s.executables = ['kramdown-rfc', 'kramdown-rfc2629', 'doilit', 'echars',
                   'kramdown-rfc-extract-markdown',
                   'kramdown-rfc-extract-sourcecode',
                   'kramdown-rfc-lsr',
                   'kdrfc', 'kramdown-rfc-cache-i-d-bibxml',
                   'kramdown-rfc-cache-subseries-bibxml',
                   'kramdown-rfc-autolink-iref-cleanup',
                   'de-gfm',
                   'kramdown-rfc-clean-svg-ids']
  s.required_ruby_version = '>= 2.3.0'
  s.author = "Carsten Bormann"
  s.email = "cabo@tzi.org"
  s.homepage = "http://github.com/cabo/kramdown-rfc"
  s.license = 'MIT'
end
