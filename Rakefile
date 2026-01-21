task :i do
  sh %{gebuin kramdown-rfc2629.gemspec}
  sh %{gebuin kramdown-rfc.gemspec}
end

task :j do
  sh %{curl -sfL https://raw.githubusercontent.com/reschke/xml2rfc/refs/heads/master/rfcxml.xslt | tr -d '\\r' > data/rfcxml.xslt.new}
  sh %{if cmp data/rfcxml.xslt data/rfcxml.xslt.new; then rm data/rfcxml.xslt.new; else mv -v data/rfcxml.xslt.new data/rfcxml.xslt; fi}
end
