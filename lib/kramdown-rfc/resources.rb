# -*- coding: utf-8 -*-

module KramdownRFC

  module ResourcesMixin
    KRAMDOWN_PERSISTENT = ENV["KRAMDOWN_PERSISTENT"]
    KRAMDOWN_PERSISTENT_VERBOSE = /v/ === KRAMDOWN_PERSISTENT

    if KRAMDOWN_PERSISTENT
      begin
        require 'net/http/persistent'
        $http = Net::HTTP::Persistent.new name: 'kramdown-rfc', proxy: :ENV
      rescue Exception => e
        warn "** Not using persistent HTTP -- #{e}"
        warn "**   To silence this message and get full speed, try:"
        warn "**     gem install net-http-persistent"
        warn "**   If this doesn't work, you can ignore this warning."
      end
    end


    REFCACHEDIR = ENV["KRAMDOWN_REFCACHEDIR"] || ".refcache"

    # warn "*** REFCACHEDIR #{REFCACHEDIR}"

    KRAMDOWN_OFFLINE = ENV["KRAMDOWN_OFFLINE"]
    KRAMDOWN_REFCACHE_REFETCH = ENV["KRAMDOWN_REFCACHE_REFETCH"]
    KRAMDOWN_REFCACHE_QUIET = ENV["KRAMDOWN_REFCACHE_QUIET"]

    def get_and_write_resource(url, fn)
      options = {}
      if ENV["KRAMDOWN_DONT_VERIFY_HTTPS"]
        options[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE
      end             # workaround for OpenSSL on Windows...
      # URI.open(url, **options) do |uf|          # not portable to older versions
      parsed = URI.parse(url)
      if parsed.scheme == 'file'
        s = File.read(parsed.path)
      else
        OpenURI.open_uri(url, **options) do |uf|
          s = uf.read
          status = uf.status[0]
          if (status.to_i / 100) != 2
            warn "*** Status code #{status} while fetching #{url}"
            return
          end
        end
      end
      File.write(fn, s)
    end

    def get_and_write_resource_persistently(url, fn)
      t1 = Time.now
      response = $http.request(URI(url))
      if response.code != "200"
        raise "Status code #{response.code} while fetching #{url}"
      else
        File.write(fn, response.body)
      end
      t2 = Time.now
      warn "(#{"%.3f" % (t2 - t1)} s)" if KRAMDOWN_PERSISTENT_VERBOSE
    end

    def get_doi(refname)
      lit = doi_fetch_and_convert(refname, fuzzy: true)
      anchor = "DOI_#{refname.gsub("/", "_")}"
      KramdownRFC::ref_to_xml(anchor, lit)
    end


    # this is now slightly dangerous as multiple urls could map to the same cachefile
    def get_and_cache_resource(url, cachefile, tvalid = 7200, tn = Time.now)
      fn = "#{REFCACHEDIR}/#{cachefile}"
      Dir.mkdir(REFCACHEDIR) unless Dir.exist?(REFCACHEDIR)
      f = File.stat(fn) rescue nil unless KRAMDOWN_REFCACHE_REFETCH
      if !KRAMDOWN_OFFLINE && (!f || tn - f.mtime >= tvalid)
        if f
          message = "renewing (stale by #{"%.1f" % ((tn-f.mtime)/86400)} days)"
          fetch_timeout = 10 # seconds, give up quickly if just renewing
        else
          message = "fetching"
          fetch_timeout = 60 # seconds; long timeout needed for Travis
        end
        $stderr.puts "#{fn}: #{message} from #{url}" unless KRAMDOWN_REFCACHE_QUIET
        if Array === url
          begin
            case url[0]
            when :DOI
              ref = get_doi(url[1])
              File.write(fn, ref)
            end
          rescue Exception => e
            warn "*** Error fetching #{url[0]} #{url[1].inspect}: #{e}"
          end
        elsif ENV["HAVE_WGET"]
          `cd #{REFCACHEDIR}; wget -t 3 -T #{fetch_timeout} -Nnv "#{url}"` # ignore errors if offline (hack)
          begin
            File.utime nil, nil, fn
          rescue Errno::ENOENT
            warn "Can't fetch #{url} -- is wget in path?"
          end
        else
          require 'open-uri'
          require 'socket'
          require 'openssl'
          require 'timeout'
          begin
            Timeout::timeout(fetch_timeout) do
              if $http
                begin         # belt and suspenders
                  get_and_write_resource_persistently(url, fn)
                rescue Exception => e
                  warn "*** Can't get with persistent HTTP: #{e}"
                  get_and_write_resource(url, fn)
                end
              else
                get_and_write_resource(url, fn)
              end
            end
          rescue OpenURI::HTTPError, Errno::EHOSTUNREACH, Errno::ECONNREFUSED,
                 SocketError, Timeout::Error => e
            warn "*** #{e} while fetching #{url}"
          end
        end
      end
      begin
        File.read(fn) # this blows up if no cache available after fetch attempt
      rescue Errno::ENOENT => e
        warn "*** #{e} for #{fn}"
      end
    end



    def self.bcp_std_ref(t, n)
      warn "*** #{t} anchors not supported in v2 format" unless $options.v3
      [name = "reference.#{t}.#{"%04d" % n.to_i}.xml",
       "#{XML_RESOURCE_ORG_PREFIX}/bibxml-rfcsubseries/#{name}"] # FOR NOW
    end

    KRAMDOWN_REFCACHETTL = (e = ENV["KRAMDOWN_REFCACHETTL"]) ? e.to_i : 3600

    KRAMDOWN_REFCACHETTL_RFC = (e = ENV["KRAMDOWN_REFCACHETTL_RFC"]) ? e.to_i : 86400*7
    KRAMDOWN_REFCACHETTL_DOI_IANA = (e = ENV["KRAMDOWN_REFCACHETTL_DOI_IANA"]) ? e.to_i : 86400
    KRAMDOWN_REFCACHETTL_DOI = (e = ENV["KRAMDOWN_REFCACHETTL_DOI"]) ? e.to_i : KRAMDOWN_REFCACHETTL_DOI_IANA
    KRAMDOWN_REFCACHETTL_IANA = (e = ENV["KRAMDOWN_REFCACHETTL_IANA"]) ? e.to_i : KRAMDOWN_REFCACHETTL_DOI_IANA

    # [subdirectory name, cache ttl in seconds, does it provide for ?anchor=]
    XML_RESOURCE_ORG_MAP = {
      "RFC" => ["bibxml", KRAMDOWN_REFCACHETTL_RFC, false,
                ->(fn, n){ [name = "reference.RFC.#{"%04d" % n.to_i}.xml",
                            "https://bib.ietf.org/public/rfc/bibxml/#{name}"] }
# wa                        "https://www.rfc-editor.org/refs/bibxml/#{name}"] }
               ],
      "I-D" => ["bibxml3", false, false,
                ->(fn, n){ [fn,
                            "https://datatracker.ietf.org/doc/bibxml3/draft-#{n.sub(/\Adraft-/, '')}.xml"] }
               ],
      "BCP" => ["bibxml-rfcsubseries", KRAMDOWN_REFCACHETTL_RFC, false,
                ->(fn, n){ Rfc2629::bcp_std_ref("BCP", n) }
               ],
      "STD" => ["bibxml-rfcsubseries", KRAMDOWN_REFCACHETTL_RFC, false,
                ->(fn, n){ Rfc2629::bcp_std_ref("STD", n) }
               ],
      "W3C" => "bibxml4",
      "3GPP" => "bibxml5",
      "SDO-3GPP" => "bibxml5",
      "ANSI" => "bibxml2",
      "CCITT" => "bibxml2",
      "FIPS" => "bibxml2",
      # "IANA" => "bibxml2",   overtaken by bibxml8
      "IEEE" => "bibxml6",    # copied over to bibxml6 2019-02-27
      "ISO" => "bibxml2",
      "ITU" => "bibxml2",
      "NIST" => "bibxml2",
      "OASIS" => "bibxml2",
      "PKCS" => "bibxml2",
      "DOI" => ["bibxml7", KRAMDOWN_REFCACHETTL_DOI, true,
                ->(fn, n){ ["computed-#{fn}", [:DOI, n] ] }, true # always_altproc
               ], # emulate old 24 h cache
      "IANA" => ["bibxml8", KRAMDOWN_REFCACHETTL_IANA, true], # ditto
    }

    # XML_RESOURCE_ORG_HOST = ENV["XML_RESOURCE_ORG_HOST"] || "xml.resource.org"
    # XML_RESOURCE_ORG_HOST = ENV["XML_RESOURCE_ORG_HOST"] || "xml2rfc.tools.ietf.org"
    XML_RESOURCE_ORG_HOST = ENV["XML_RESOURCE_ORG_HOST"] || "bib.ietf.org"
    XML_RESOURCE_ORG_PREFIX = ENV["XML_RESOURCE_ORG_PREFIX"] ||
                              "https://#{XML_RESOURCE_ORG_HOST}/public/rfc"
    KRAMDOWN_USE_TOOLS_SERVER = ENV["KRAMDOWN_USE_TOOLS_SERVER"]

    KRAMDOWN_NO_TARGETS = ENV['KRAMDOWN_NO_TARGETS']
    KRAMDOWN_KEEP_TARGETS = ENV['KRAMDOWN_KEEP_TARGETS']

    XML_RESOURCE_DEFAULT_FILENAME = "reference.%{bibtag}.xml"

    @@bibtags = {}

    def _source_dirs
      @@bibtags[:dirs] || []
    end

    def _sources
      @@bibtags[:sources] || {}
    end

    def resolve_resource_from_dirs(fname, anchor)
      _source_dirs.each do |dir|
        path = File.join(dir, fname)
        if File.exist?(path)
          return path
        end
      end
      return nil
    end

    def _url_or_filename_template(rtype, rname, template)
      bibtag = "#{rtype}.#{rname}"
      bibref = rname
      repl = {
        bibtag: bibtag,
        bibref: bibref,
      }
      return template % repl
    end

    def _filename(rtype, rname, template = nil)
      return _url_or_filename_template(rtype, rname, template || XML_RESOURCE_DEFAULT_FILENAME)
    end

    def _url(rtype, rname, url)
      return _url_or_filename_template(rtype, rname, url)
    end

    def resolve_resource_from_config(rtype, rname, anchor)
      # Simple things first: see if we can get the rtype from our local
      # bibtags sources.
      res = _sources[rtype.to_s] || nil
      if not res
        return nil
      end

      if not res.include?("url")
        warn "*** Invalid resource source definition for #{rtype}: must include URL field."
        return nil
      end

      # Process the URL, file name patterns.
      fname = _filename(rtype, rname, res['filename'])
      url = _url(rtype, rname, res['url'])

      return [
        '', # ignored
        res['ttl'] || KRAMDOWN_REFCACHETTL,
        res['rewrite_anchor'] || false,
        ->(fn, n) { [fname, url] },
        true
      ]
    end

    def resolve_resource(rtype, rname, anchor, never_altproc=true, stand_alone=true)
      # Filename pattern
      fn = _filename(rtype, rname)
      fn.gsub!('/', '_')

      # Try a configured directory source first, if any
      path = resolve_resource_from_dirs(fn, anchor)
      if path
        # If we have a local path, we can just return some defaults for the
        # entry.
        ret = ["file://#{path}", fn, KRAMDOWN_REFCACHETTL]
        return ret
      end

      # Prefer from configuration, fall back to resource map
      xro = resolve_resource_from_config(rtype, rname, anchor)
      if not xro

        xro = XML_RESOURCE_ORG_MAP[rtype]
        if not xro
          warn "*** No citation source found for: #{rtype}.#{rname}"
          return [nil, fn, KRAMDOWN_REFCACHETTL]
        end
      end

      # Process either source the same.
      never_altproc = rname.dup.sub!(/^[.]/, "")
      sub, ttl, can_anchor, altproc, always_altproc = xro
      ttl ||= KRAMDOWN_REFCACHETTL  # everything but RFCs might change a lot
      puts "*** Huh: #{fn}" unless sub
      if altproc && !never_altproc && (!KRAMDOWN_USE_TOOLS_SERVER || always_altproc)
        fn, url = altproc.call(fn, rname)
      else
        url = "#{XML_RESOURCE_ORG_PREFIX}/#{sub}/#{fn}"
        fn = "alt-#{fn}" if never_altproc || KRAMDOWN_USE_TOOLS_SERVER
      end
      if not Array === url
        if can_anchor
          url << "?anchor=#{anchor}"
          fn[/.xml$/] = "--anchor=#{anchor}.xml"
        elsif !stand_alone
          warn "*** selecting a custom anchor '#{anchor}' for '#{bib1}' requires stand_alone mode"
          warn "    the output will need manual editing to correct this"
        end
      end

      fn = fn.gsub('/', '_')
      return url, fn, ttl
    end


    # return XML entity name, url, rewrite_anchor flag
    def bibtagsys(bib, anchor=nil, stand_alone=true)
      if bib =~ /\Arfc(\d+)/i
        rfc4d = "%04d" % $1.to_i
        [bib.upcase,
         "#{XML_RESOURCE_ORG_PREFIX}/bibxml/reference.RFC.#{rfc4d}.xml"]
      elsif $options.v3 && bib =~ /\A(bcp|std)(\d+)/i
        n4d = "%04d" % $2.to_i
        [bib.upcase,
         "#{XML_RESOURCE_ORG_PREFIX}/bibxml-rfcsubseries-new/reference.#{$1.upcase}.#{n4d}.xml"]
      elsif bib =~ /\A([-A-Z0-9]+)\.([A-Za-z_0-9.\(\)\/\+-]+)/
        bib1 = ::Kramdown::Parser::RFC2629Kramdown.idref_cleanup(bib)

        url, fn, ttl = resolve_resource($1, $2, anchor, stand_alone=stand_alone)
        [bib1, url]
      end
    end

    def yaml_load(input, *args)
     begin
      if YAML.respond_to?(:safe_load)
        begin
          YAML.safe_load(input, *args)
        rescue ArgumentError
          YAML.safe_load(input, permitted_classes: args[0], permitted_symbols: args[1], aliases: args[2])
        end
      else
        YAML.load(input)
      end
     rescue Psych::SyntaxError => e
       warn "*** YAML syntax error: #{e}"
     end
    end

    BIBTAGS_KEYS = ['url', 'filename', 'ttl', 'rewrite_anchor']

    def _merge_sources(target, source)
      source.each do |prefix, settings|
        target[prefix] ||= {}
        settings.each do |key, value|
          if BIBTAGS_KEYS.include?(key)
            target[prefix][key] = value
          end
        end
      end
    end

    def process_bibtags_meta(bibtags)
      sources = {}
      dirs = []

      # Process 'from' section
      (bibtags['from'] || []).each do |path|
        path = File.expand_path(path)
        if File.directory?(path)
          # Add directory to search paths
          dirs << path
        elsif File.exist?(path)
          # Load YAML, add sources (if any) to existing map.
          content = File.read(path, coding: "UTF-8")
          yaml = yaml_load(content)

          _merge_sources(sources, yaml['sources'] || {})
        end
      end

      # Merge collected sources with 'sources' section
      _merge_sources(sources, bibtags['sources'] || {})

      @@bibtags = {
        :dirs => dirs,
        :sources => sources,
      }
    end

  end # module ResourcesMixin

  class Resources
    include ResourcesMixin

  end # class Resources

end # module KramdownRFC
