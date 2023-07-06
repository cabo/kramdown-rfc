require 'open-uri'
require 'json'
require 'yaml'

ACCEPT_CITE_JSON = {"Accept" => "application/citeproc+json"}

def doi_fetch_and_convert(doi, fuzzy: false, verbose: false, site: "https://dx.doi.org")
  doipath = doi.sub(/^([0-9.]+)_/) {"#$1/"} # convert initial _ back to /
  # warn "** SUB #{doi} #{doipath}" if doi != doipath
  cite = JSON.parse(URI("#{site}/#{doipath}").open(ACCEPT_CITE_JSON).read)
  puts cite.to_yaml if verbose
  lit = {}
  ser = lit["seriesinfo"] = {}
  lit["title"] = cite["title"]
  if (st = cite["subtitle"]) && Array === st # defensive
    st.delete('')
    if st != []
      lit["title"] << ": " << st.join("; ")
    end
  end
  if authors = cite["author"]
    lit["author"] = authors.map do |au|
      lau = {}
      if (f = au["family"])
        if (g = au["given"])
          lau["name"] = "#{g} #{f}"
          lau["ins"] =  "#{g[0]}. #{f}"
        else
          lau["name"] = "#{f}"
#          lau["ins"] =  "#{g[0]}. #{f}"
        end
      end
      if (f = au["affiliation"]) && Array === f
        names = f.map { |affn|
          if Hash === affn && (n = affn["name"]) && String === n
            n
          end
        }.compact
        if names.size > 0
          lau["org"] = names.join("; ")
        end
      end
      lau
    end
  end
  if iss = cite["issued"]
    if dp = iss["date-parts"]
      if Integer === (dp = dp[0])[0]
        lit["date"] = ["%04d" % dp[0], *dp[1..-1].map {|p| "%02d" % p}].join("-")
      end
    end
  end
  if !lit.key?("date") && fuzzy && (iss = cite["created"])
    if dp = iss["date-parts"]
      if Integer === (dp = dp[0])[0]
        lit["date"] = ["%04d" % dp[0], *dp[1..-1].map {|p| "%02d" % p}].join("-")
      end
    end
  end
  if (ct = cite["container-title"]) && ct != []
    info = []
    if v = cite["volume"]
      vi = "vol. #{v}"
      if (v = cite["journal-issue"]) && (issue = v["issue"])
        vi << ", no. #{issue}"
      end
      info << vi
    end
    if p = cite["page"]
      info << "pp. #{p}"
    end
    rhs = info.join(", ")
    if info != []
      ser[ct] = rhs
    else
      spl = ct.split(" ")
      ser[spl[0..-2].join(" ")] = spl[-1]
    end
  elsif pub = cite["publisher"]
    info = []
    if t = cite["type"]
      info << t
    end
    rhs = info.join(", ")
    if info != []
      ser[pub] = rhs
    else
      spl = pub.split(" ")
      ser[spl[0..-2].join(" ")] = spl[-1]
    end
  end
  ser["DOI"] = cite["DOI"]
  lit
end
