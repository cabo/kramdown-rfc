spec = Gem::Specification.new do |s|
  s.name = 'kramdown-rfc2629'
  s.version = '0.13.3'
  s.summary = "Kramdown extension for generating RFC 2629 XML."
  s.description = %{An RFC2629 (XML2RFC) generating backend for Thomas Leitner's
"kramdown" markdown parser.  Mostly useful for RFC writers.}
  s.add_dependency('kramdown', '~> 0.13')
  s.files = Dir['lib/**/*.rb'] + %w(README.md kramdown-rfc2629.gemspec bin/kramdown-rfc2629 data/kramdown-rfc2629.erb)
  s.require_path = 'lib'
  s.executables = ['kramdown-rfc2629']
  s.default_executable = 'kramdown-rfc2629'
  s.required_ruby_version = '>= 1.9.2'
  s.requirements = 'wget'
  #  s.has_rdoc = true
  s.author = "Carsten Bormann"
  s.email = "cabo@tzi.org"
  s.homepage = "http://github.com/cabo/kramdown-rfc2629"
end
