require 'uri'
require 'net/http'
require 'open3'
require 'ostruct'

module KramdownRFC

class KDRFC

  attr_reader :options

  def initialize
    @options = OpenStruct.new
  end

  # )))

KDRFC_PREPEND = [ENV["KDRFC_PREPEND"]].compact

def v3_flag?
  @options.v3 ? ["--v3"] : []
end

def process_mkd(input, output)
  warn "* converting locally from markdown #{input} to xml #{output}" if @options.verbose
  o, s = Open3.capture2(*KDRFC_PREPEND, "kramdown-rfc2629", *v3_flag?, input)
  if s.success?
    File.open(output, "w") do |fo|
      fo.print(o)
    end
    warn "* #{output} written" if @options.verbose
  else
    raise IOError.new("*** kramdown-rfc failed, status #{s.exitstatus}")
  end
end

def run_idnits(txt_fn)
  unless system("idnits", txt_fn)
    warn "*** problem #$? running idnits"
  end
end

def process_xml(*args)
  if @options.remote
    process_xml_remotely(*args)
  else
    process_xml_locally(*args)
  end
end

def process_xml_locally(input, output, *flags)
  warn "* converting locally from xml #{input} to txt #{output}" if @options.verbose
  begin
    o, s = Open3.capture2(*KDRFC_PREPEND, "xml2rfc", *v3_flag?, *flags, input)
    puts o
    if s.success?
      warn "* #{output} written" if @options.verbose
    else
      raise IOError.new("*** xml2rfc failed, status #{s.exitstatus} (possibly try with -r)")
    end
  rescue Errno::ENOENT
    warn "*** falling back to remote xml2rfc processing (web service)" # if @options.verbose
    process_xml_remotely(input, output, *flags)
  end
end

XML2RFC_WEBSERVICE = ENV["KRAMDOWN_XML2RFC_WEBSERVICE"] ||
                     'http://xml2rfc.tools.ietf.org/cgi-bin/xml2rfc-dev.cgi'

MODE_AS_FORMAT = {
  nil => {                    # v2
    "--text" => "txt/ascii",
    "--html" => "html/ascii",
  },
  true => {                     # v3
    "--text" => "txt/v3ascii",
    "--html" => "html/v3ascii",
    "--v2v3" => "v3xml/ascii",
  }
}

def process_xml_remotely(input, output, *flags)
  warn "* converting remotely from xml #{input} to txt #{output}" if @options.verbose
  format = flags[0] || "--text"
  # warn [:V3, @options.v3].inspect
  maf = MODE_AS_FORMAT[@options.v3][format]
  unless maf
    raise ArgumentError.new("*** don't know how to convert remotely from xml #{input} to txt #{output}")
  end
  url = URI(XML2RFC_WEBSERVICE)
  req = Net::HTTP::Post.new(url)
  form = [["modeAsFormat", maf],
          ["type", "binary"],
          ["input", File.open(input),
           {filename: "input.xml",
            content_type: "text/plain"}]]
  diag = ["url/form: ", url, form].inspect
  req.set_form(form, 'multipart/form-data')
  res = Net::HTTP::start(url.hostname, url.port,
                         :use_ssl => url.scheme == 'https' ) {|http|
    http.request(req)
  }
  case res
  when Net::HTTPOK
    case res.content_type
    when 'application/octet-stream'
      if res.body == ''
        raise IOError.new("*** HTTP response is empty with status #{res.code}, not written")
      end
      File.open(output, "w") do |fo|
        fo.print(res.body)
      end
      warn "* #{output} written" if @options.verbose
    else
      warning = "*** HTTP response has unexpected content_type #{res.content_type} with status #{res.code}, #{diag}"
      warning << "\n"
      warning << res.body
      raise IOError.new(warning)
    end
  else
    raise IOError.new("*** HTTP response: #{res.code}, #{diag}")
  end
end

def process_the_xml(fn, base)
  process_xml(fn, "#{base}.prepped.xml", "--preptool") if @options.prep
  process_xml(fn, "#{base}.v2v3.xml", "--v2v3") if @options.v2v3
  process_xml(fn, "#{base}.txt") if @options.txt || @options.idnits
  process_xml(fn, "#{base}.html", "--html") if @options.html
  process_xml(fn, "#{base}.pdf", "--pdf") if @options.pdf
  run_idnits("#{base}.txt") if @options.idnits
end

def process(fn)
  case fn
  when /(.*)\.xml\z/
    if @options.xml_only
      warn "*** You already have XML"
    else                        # FIXME: copy/paste
      process_the_xml(fn, $1)
    end
  when /(.*)\.mk?d\z/
    xml = "#$1.xml"
    process_mkd(fn, xml)
    process_the_xml(xml, $1) unless @options.xml_only
  else
    raise ArgumentError.new("Unknown file type: #{fn}")
  end
end

# (((
end

end
