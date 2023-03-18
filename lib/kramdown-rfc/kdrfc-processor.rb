require 'uri'
require 'net/http'
require 'net/http/persistent'
require 'open3'
require 'ostruct'
require 'json'

module KramdownRFC

class KDRFC

  attr_reader :options

  def initialize
    @options = OpenStruct.new
  end

  # )))

KDRFC_PREPEND = [ENV["KDRFC_PREPEND"]].compact

def v3_flag?
  [*(@options.v3 ? ["--v3"] : []),
   *(@options.v2 ? ["--v2"] : [])]
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

def run_idnits(*args)
  if @options.remote
    run_idnits_remotely(*args)
  else
    run_idnits_locally(*args)
  end
end

def run_idnits_locally(txt_fn)
  unless system("idnits1", txt_fn)
    warn "*** problem #$? running idnits" if @options.verbose
    warn "*** problem running idnits -- falling back to remote idnits processing"
    run_idnits_remotely(txt_fn)
  end
end

# curl -s https://author-tools.ietf.org/api/idnits -X POST -F file=@draft-ietf-core-comi.txt -F hidetext=true
IDNITS_WEBSERVICE = ENV["KRAMDOWN_IDNITS_WEBSERVICE"] ||
                     'https://author-tools.ietf.org/api/idnits'

def run_idnits_remotely(txt_fn)
  url = URI(IDNITS_WEBSERVICE)
  req = Net::HTTP::Post.new(url)
  form = [["file", File.open(txt_fn),
           {filename: "input.txt",
            content_type: "text/plain"}],
          ["hidetext", "true"]]
  diag = ["url/form: ", url, form].inspect
  req.set_form(form, 'multipart/form-data')
  warn "* requesting idnits at #{url}" if @options.verbose
  t0 = Time.now
  res = persistent_http.request(url, req)
  warn "* elapsed time: #{Time.now - t0}" if @options.verbose
  case res
  when Net::HTTPBadRequest
    result = checked_json(res.body)
    raise IOError.new("*** Remote Error: #{result["error"]}")
  when Net::HTTPOK
    case res.content_type
    when 'text/plain'
      if res.body == ''
        raise IOError.new("*** HTTP response is empty with status #{res.code}, not written")
      end
      puts res.body
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

# curl https://author-tools.ietf.org/api/render/text -X POST -F "file=@..."
XML2RFC_WEBSERVICE = ENV["KRAMDOWN_XML2RFC_WEBSERVICE"] ||
                     'https://author-tools.ietf.org/api/render/'

MODE_AS_FORMAT = {
    "--text" => "text",
    "--html" => "html",
    "--v2v3" => "xml",
    "--pdf" => "pdf",
}

def checked_json(t)
  begin
    JSON.load(t)
  rescue => e
    raise IOError.new("*** JSON result: #{e.detailed_message}, #{diag}")
  end
end

def persistent_http
  $http ||= Net::HTTP::Persistent.new name: 'kramdown-rfc'
end

def process_xml_remotely(input, output, *flags)

  format = flags[0] || "--text"
  warn "* converting remotely from xml #{input} to #{format} #{output}" if @options.verbose
  maf = MODE_AS_FORMAT[format]
  unless maf
    raise ArgumentError.new("*** don't know how to convert remotely from xml #{input} to #{format} #{output}")
  end
  url = URI(XML2RFC_WEBSERVICE + maf)
  req = Net::HTTP::Post.new(url)
  form = [["file", File.open(input),
           {filename: "input.xml",
            content_type: "text/plain"}]]
  diag = ["url/form: ", url, form].inspect
  req.set_form(form, 'multipart/form-data')
  warn "* requesting at #{url}" if @options.verbose
  t0 = Time.now
  res = persistent_http.request(url, req)
  warn "* elapsed time: #{Time.now - t0}" if @options.verbose
  case res
  when Net::HTTPBadRequest
    result = checked_json(res.body)
    raise IOError.new("*** Remote Error: #{result["error"]}")
  when Net::HTTPOK
    case res.content_type
    when 'application/json'
      if res.body == ''
        raise IOError.new("*** HTTP response is empty with status #{res.code}, not written")
      end
      # warn "* res.body #{res.body}" if @options.verbose
      result = checked_json(res.body)
      if logs = result["logs"]
        if errors = logs["errors"]
          errors.each do |err|
            warn("*** Error: #{err}")
          end
        end
        if warnings = logs["warnings"]
          warnings.each do |w|
            warn("** Warning: #{w}")
          end
        end
      end
      raise IOError.new("*** No useful result from remote") unless result["url"]
      res = persistent_http.request(URI(result["url"]))
      warn "* result content type #{res.content_type}" if @options.verbose
      if res.body == ''
        raise IOError.new("*** Second HTTP response is empty with status #{res.code}, not written")
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
  when /(.*)\.txt\z/
    run_idnits(fn) if @options.idnits
  else
    raise ArgumentError.new("Unknown file type: #{fn}")
  end
end

# (((
end

end
