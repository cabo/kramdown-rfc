#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'kramdown-rfc2629'
require 'kramdown-rfc/parameterset'
require 'kramdown-rfc/refxml'
require 'kramdown-rfc/rfc8792'
require 'yaml'
require 'kramdown-rfc/erb'
require 'date'

# try to get this from gemspec.
KDRFC_VERSION=Gem.loaded_specs["kramdown-rfc2629"].version rescue "unknown-version"

Encoding.default_external = "UTF-8" # wake up, smell the coffee

# Note that this doesn't attempt to handle HT characters
def remove_indentation(s)
  l = s.lines
  indent = l.grep(/\S/).map {|l| l[/^\s*/].size}.min
  l.map {|li| li.sub(/^ {0,#{indent}}/, "")}.join
end

def add_quote(s)
  l = s.lines
  l.map {|li| "> #{li}"}.join
end

def process_chunk(s, nested, dedent, fold, quote)
  process_includes(s) if nested
  s = remove_indentation(s) if dedent
  s = fold8792_1(s, *fold) if fold
  s = add_quote(s) if quote
  s
end

def process_includes(input)
 input.gsub!(/^\{::include((?:-[a-z0-9]+)*)\s+(.*?)\}/) {
  include_flags = $1
  fn = [$2]
  chunks = false
  nested = false
  dedent = false
  fold = false
  quote = false
  include_flags.split("-") do |flag|
    case flag
    when ""
    when "nested"
      nested = true
    when "quote"
      quote = true
    when "dedent"
      dedent = true
    when /\Afold(\d*)(left(\d*))?(dry)?\z/
      fold = [$1.to_i,            # col 0 for ''
              ($3.to_i if $2),    # left 0 for '', nil if no "left"
              $4]                 # dry
    when "all", "last"
      fn = fn.flat_map{|n| Dir[n]}
      fn = [fn.last] if flag == "last"
      chunks = fn.map{ |f|
        ret = process_chunk(File.read(f), nested, dedent, fold, quote)
        nested = false; dedent = false; fold = false; quote = false
        ret
      }
    else
      warn "** unknown include flag #{flag}"
    end
  end
  chunks = fn.map{|f| File.read(f)} unless chunks # no all/last
  chunks = chunks.map {|ch| process_chunk(ch, nested, dedent, fold, quote)}
  chunks.join.chomp
 }
end


def boilerplate(key)
  case key.downcase
  when /\Abcp14(info)?(\+)?(-tagged)?\z/i
    ret = ''
    if $1
      ret << <<RFC8174ise
Although this document is not an IETF Standards Track publication, it
adopts the conventions for normative language to provide clarity of
instructions to the implementer.
RFC8174ise
    end
    ret << <<RFC8174
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED",
"MAY", and "OPTIONAL" in this document are to be interpreted as
described in BCP 14 {{!RFC2119}} {{!RFC8174}} when, and only when, they
appear in all capitals, as shown here.
RFC8174
    if $2
      ret << <<PLUS
These words may also appear in this document in
lower case as plain English words, absent their normative meanings.
PLUS
    end
    if $3
      ($options.v3_used ||= []) << "** need --v3 to tag bcp14"
      ret << <<TAGGED

*[MUST]: <bcp14>
*[MUST NOT]: <bcp14>
*[REQUIRED]: <bcp14>
*[SHALL]: <bcp14>
*[SHALL NOT]: <bcp14>
*[SHOULD]: <bcp14>
*[SHOULD NOT]: <bcp14>
*[RECOMMENDED]: <bcp14>
*[NOT RECOMMENDED]: <bcp14>
*[MAY]: <bcp14>
*[OPTIONAL]: <bcp14>
TAGGED
    end
    ret
  else
    warn "** Unknwon boilerplate key: #{key}"
    "{::boilerplate #{key}}"
  end
end

def do_the_tls_dance
  begin
    require 'openssl'
    File.open(OpenSSL::X509::DEFAULT_CERT_FILE) do end
    # This guards against having an unreadable cert file (yes, that appears to happen a lot).
  rescue
    if Dir[File.join(OpenSSL::X509::DEFAULT_CERT_DIR, "*.pem")].empty?
      # This guards against having no certs at all, not against missing the right one for IETF.
      # Oh well.
      warn "** Configuration problem with OpenSSL certificate store."
      warn "**   You may want to examine #{OpenSSL::X509::DEFAULT_CERT_FILE}"
      warn "**    and #{OpenSSL::X509::DEFAULT_CERT_DIR}."
      warn "**   Activating suboptimal workaround."
      warn "**   Occasionally run `certified-update` to maintain that workaround."
      require 'certified'
    end
  end
end

RE_NL = /(?:\n|\r|\r\n)/
RE_SECTION = /---(?: +(\w+)(-?))?\s*#{RE_NL}(.*?#{RE_NL})(?=---(?:\s+\w+-?)?\s*#{RE_NL}|\Z)/m

NMDTAGS = ["{:/nomarkdown}\n\n", "\n\n{::nomarkdown}\n"]

NORMINFORM = { "!" => :normative, "?" => :informative }

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
   exit 65 # EX_DATAERR
 end
end

def process_kramdown_options(coding_override = nil,
                             smart_quotes = nil, typographic_symbols = nil,
                             header_kramdown_options = nil)

  ascii_target = coding_override && coding_override =~ /ascii/
  suppress_typography = ascii_target || $options.v3
  entity_output = ascii_target ? :numeric : :as_char;

  options = {input: 'RFC2629Kramdown', entity_output: entity_output, link_defs: {}}

  if smart_quotes.nil? && suppress_typography
    smart_quotes = false
  end
  if smart_quotes == false
    smart_quotes = ["'".ord, "'".ord, '"'.ord, '"'.ord]
  end
  case smart_quotes
  when Array
    options[:smart_quotes] = smart_quotes
  when nil, true
    # nothin
  else
    warn "*** Can't deal with smart_quotes value #{smart_quotes.inspect}"
  end

  if typographic_symbols.nil? && suppress_typography
    typographic_symbols = false
  end
  if typographic_symbols == false
    typographic_symbols = Hash[::Kramdown::Parser::Kramdown::TYPOGRAPHIC_SYMS.map { |k, v|
                                 if Symbol === v
                                   [v.intern, k]
                                 end
                               }.compact]
  end
  # warn [:TYPOGRAPHIC_SYMBOLS, typographic_symbols].to_yaml
  case typographic_symbols
  when Hash
    options[:typographic_symbols] = typographic_symbols
  when nil, true
    # nothin
  else
    warn "*** Can't deal with typographic_symbols value #{typographic_symbols.inspect}"
  end

  if header_kramdown_options
    options.merge! header_kramdown_options
  end

  $global_markdown_options = options   # For nested calls in bibref annotation processing and xref text

  options
end

XREF_SECTIONS_RE = ::Kramdown::Parser::RFC2629Kramdown::SECTIONS_RE
XSR_PREFIX = "#{XREF_SECTIONS_RE} of "
XSR_SUFFIX = ", (#{XREF_SECTIONS_RE})| \\((#{XREF_SECTIONS_RE})\\)"
XREF_TXT = ::Kramdown::Parser::RFC2629Kramdown::XREF_TXT
XREF_TXT_SUFFIX = " \\(#{XREF_TXT}\\)"

def spacify_re(s)
  s.gsub(' ', '[\u00A0\s]+')
end

def xml_from_sections(input)

  unless ENV["KRAMDOWN_NO_SOURCE"]
    require 'kramdown-rfc/gzip-clone'
    require 'base64'
    compressed_input = Gzip.compress_m0(input)
    $source = Base64.encode64(compressed_input)
  end

  sections = input.scan(RE_SECTION)
  # resulting in an array; each section is [section-label, nomarkdown-flag, section-text]

  # the first section is a YAML with front matter parameters (don't put a label here)
  # We put back the "---" plus gratuitous blank lines to hack the line number in errors
  yaml_in = input[/---\s*/] << sections.shift[2]
  ps = KramdownRFC::ParameterSet.new(yaml_load(yaml_in, [Date], [], true))

  if v = ps[:v]
    warn "*** unsupported RFCXML version #{v}" if v != 3
    if $options.v2
      warn "*** command line --v2 wins over document's 'v: #{v}'"
    else
      $options.v3 = true
      $options.v = 3
      ps.default!(:stand_alone, true)
      ps.default!(:ipr, "trust200902")
      ps.default!(:pi,  {"toc" => true, "sortrefs" => true, "symrefs" => true})
    end
  end

  if o = ps[:'autolink-iref-cleanup']
    $options.autolink_iref_cleanup = o
  end

  coding_override = ps.has(:coding)
  smart_quotes = ps[:smart_quotes]
  typographic_symbols = ps[:typographic_symbols]
  header_kramdown_options = ps[:kramdown_options]

  kramdown_options = process_kramdown_options(coding_override,
                                              smart_quotes, typographic_symbols,
                                              header_kramdown_options)

  # all the other sections are put in a Hash, possibly concatenated from parts there
  sechash = Hash.new{ |h,k| h[k] = ""}
  snames = []                   # a stack of section names
  sections.each do |sname, nmdflag, text|
    # warn [:SNAME, sname, nmdflag, text[0..10]].inspect
    nmdin, nmdout = {
      "-" => ["", ""],          # stay in nomarkdown
      "" => NMDTAGS, # pop out temporarily
    }[nmdflag || ""]
    if sname
      snames << sname           # "--- label" -> push label (now current)
    else
      snames.pop                # just "---" -> pop label (previous now current)
    end
    sechash[snames.last] << "#{nmdin}#{text}#{nmdout}"
  end

  ref_replacements = { }
  anchor_to_bibref = { }

  displayref = {}

  [:ref, :normative, :informative].each do |sn|
    if refs = ps.has(sn)
      warn "*** bad section #{sn}: #{refs.inspect}" unless refs.respond_to? :each
      refs.each do |k, v|
        if v.respond_to? :to_str
          if bibtagsys(v)       # enable "foo: RFC4711" as a custom anchor definition
            anchor_to_bibref[k] = v.to_str
          end
          ref_replacements[v.to_str] = k
        end
        if Hash === v
          if aliasname = v.delete("-")
            ref_replacements[aliasname] = k
          end
          if bibref = v.delete("=")
            anchor_to_bibref[k] = bibref
          end
          if dr = v.delete("display")
            displayref[k] = dr
          end
        end
      end
    end
  end
  open_refs = ps[:ref] || { }       # consumed

  norm_ref = { }

  # convenience replacement of {{-coap}} with {{I-D.ietf-core-coap}}
  # collect normative/informative tagging {{!RFC2119}} {{?RFC4711}}
  sechash.each do |k, v|
    next if k == "fluff"
    v.gsub!(/{{(#{
      spacify_re(XSR_PREFIX)
    })?(?:([?!])(-)?|(-))([\w._\-]+)(?:=([\w.\/_\-]+))?(#{
      XREF_TXT_SUFFIX
    })?(#{
      spacify_re(XSR_SUFFIX)
    })?}}/) do |match|
      xsr_prefix = $1
      norminform = $2
      replacing = $3 || $4
      word = $5
      bibref = $6
      xrt_suffix = $7
      xsr_suffix = $8
      if replacing
        if new = ref_replacements[word]
          word = new
        else
          warn "*** no alias replacement for {{-#{word}}}"
          word = "-#{word}"
        end
      end       # now, word is the anchor
      if bibref
        if old = anchor_to_bibref[word]
          if bibref != old
            warn "*** conflicting definitions for xref #{word}: #{old} != #{bibref}"
          end
        else
          anchor_to_bibref[word] = bibref
        end
      end

      # things can be normative in one place and informative in another -> normative
      # collect norm/inform above and assign it by priority here
      if norminform
        norm_ref[word] ||= norminform == '!' # one normative ref is enough
      end
      "{{#{xsr_prefix}#{word}#{xrt_suffix}#{xsr_suffix}}}"
    end
  end

  [:normative, :informative].each do |k|
    ps.rest[k.to_s] ||= { }
  end

  norm_ref.each do |k, v|
    # could check bibtagsys here: needed if open_refs is nil or string
    target = ps.has(v ? :normative : :informative)
    warn "*** overwriting #{k}" if target.has_key?(k)
    target[k] = open_refs[k] # add reference to normative/informative
  end
  # note that unused items from ref are considered OK, therefore no check for that here

  # also should allow norm/inform check of other references
  # {{?coap}} vs. {{!coap}} vs. {{-coap}} (undecided)
  # or {{?-coap}} vs. {{!-coap}} vs. {{-coap}} (undecided)
  # could require all references to be decided by a global flag
  overlap = [:normative, :informative].map { |s| (ps.has(s) || { }).keys }.reduce(:&)
  unless overlap.empty?
    warn "*** #{overlap.join(', ')}: both normative and informative"
  end

  stand_alone = ps[:stand_alone]

  [:normative, :informative].each do |sn|
    if refs = ps[sn]
      refs.each do |k, v|
        href = ::Kramdown::Parser::RFC2629Kramdown.idref_cleanup(k)
        kramdown_options[:link_defs][k] = ["##{href}", nil]   # allow [RFC2119] in addition to {{RFC2119}}

        bibref = anchor_to_bibref[k] || k
        bts, url = bibtagsys(bibref, k, stand_alone)
        if bts && (!v || v == {} || v.respond_to?(:to_str))
          if stand_alone
            a = %{{: anchor="#{k}"}}
            sechash[sn.to_s] << %{\n#{NMDTAGS[0]}\n![:include:](#{bts})#{a}\n#{NMDTAGS[1]}\n}
          else
            bts.gsub!('/', '_')
            (ps.rest["bibxml"] ||= []) << [bts, url]
            sechash[sn.to_s] << %{&#{bts};\n} # ???
          end
        else
          unless v && Hash === v
            warn "*** don't know how to expand ref #{k}"
            next
          end
          if bts && !v.delete("override")
            warn "*** warning: explicit settings completely override canned bibxml in reference #{k}"
          end
          sechash[sn.to_s] << KramdownRFC::ref_to_xml(href, v)
        end
      end
    end
  end

  erbfilename = File.expand_path '../../../data/kramdown-rfc2629.erb', __FILE__
  erbfile = File.read(erbfilename, coding: "UTF-8")
  erb = ERB.trim_new(erbfile, '-')
  # remove redundant nomarkdown pop outs/pop ins as they confuse kramdown
  input = erb.result(binding).gsub(%r"{::nomarkdown}\s*{:/nomarkdown}"m, "")
  ps.warn_if_leftovers
  sechash.delete("fluff")       # fluff is a "commented out" section
  if !sechash.empty?            # any sections unused by the ERb file?
    warn "*** sections left #{sechash.keys.inspect}!"
  end

  [input, kramdown_options, coding_override]
end

XML_RESOURCE_ORG_PREFIX = Kramdown::Converter::Rfc2629::XML_RESOURCE_ORG_PREFIX

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
  elsif bib =~ /\A([-A-Z0-9]+)\./ &&
        (xro = Kramdown::Converter::Rfc2629::XML_RESOURCE_ORG_MAP[$1])
    dir, _ttl, rewrite_anchor = xro
    bib1 = ::Kramdown::Parser::RFC2629Kramdown.idref_cleanup(bib)
    if anchor && bib1 != anchor
      if rewrite_anchor
        a = %{?anchor=#{anchor}}
      else
        if !stand_alone
          warn "*** selecting a custom anchor '#{anchor}' for '#{bib1}' requires stand_alone mode"
          warn "    the output will need manual editing to correct this"
        end
      end
    end
    [bib1,
     "#{XML_RESOURCE_ORG_PREFIX}/#{dir}/reference.#{bib}.xml#{a}"]
  end
end

def read_encodings
  encfilename = File.expand_path '../../../data/encoding-fallbacks.txt', __FILE__
  encfile = File.read(encfilename, coding: "UTF-8")
  Hash[encfile.lines.map{|l|
         l.chomp!;
         x, s = l.split(" ", 2)
         [x.hex.chr(Encoding::UTF_8), s || " "]}]
end

FALLBACK = read_encodings

def expand_tabs(s, tab_stops = 8)
  s.gsub(/([^\t\n]*)\t/) do
    $1 + " " * (tab_stops - ($1.size % tab_stops))
  end
end


require 'optparse'
require 'ostruct'

$options ||= OpenStruct.new
op = OptionParser.new do |opts|
  opts.banner = <<BANNER
Usage: kramdown-rfc2629 [options] [file.md] > file.xml
Version: #{KDRFC_VERSION}
BANNER
  opts.on("-V", "--version", "Show version and exit") do |v|
    puts "kramdown-rfc #{KDRFC_VERSION}"
    exit
  end
  opts.on("-H", "--help", "Show option summary and exit") do |v|
    puts opts
    exit
  end
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    $options.verbose = v
  end
  opts.on("-3", "--[no-]v3", "Use RFCXML v3 processing rules") do |v|
    $options.v3 = v
  end
  opts.on("-2", "--[no-]v2", "Use RFCXML v2 processing rules") do |v|
    $options.v2 = v
  end
end
op.parse!

if $options.v2 && $options.v3
  warn "*** can't have v2 and eat v3 cake"
  $options.v2 = false
end

if $options.v3.nil? && !$options.v2
  if Time.now.to_i >= 1645567342 # Time.parse("2022-02-22T22:02:22Z").to_i
    $options.v3 = true           # new default from the above date
  end
end

warn "*** v2 #{$options.v2.inspect} v3 #{$options.v3.inspect}" if $options.verbose

input = ARGF.read
if input[0] == "\uFEFF"
   warn "*** There is a leading byte order mark. Ignored."
   input[0..0] = ''
end
if input[-1] != "\n"
  # warn "*** added missing newline at end"
  input << "\n"                 # fix #26
end
process_includes(input) unless ENV["KRAMDOWN_SAFE"]
input.gsub!(/^\{::boilerplate\s+(.*?)\}/) {
  boilerplate($1)
}
if input =~ /[\t]/
   warn "*** Input contains HT (\"tab\") characters. Undefined behavior will ensue."
   input = expand_tabs(input)
end

if input =~ /\A---/        # this is a sectionized file
  do_the_tls_dance unless ENV["KRAMDOWN_DONT_VERIFY_HTTPS"]
  input, options, coding_override = xml_from_sections(input)
else
  options = process_kramdown_options # all default
end
if input =~ /\A<\?xml/          # if this is a whole XML file, protect it
  input = "{::nomarkdown}\n#{input}\n{:/nomarkdown}\n"
end

if $options.v3_used && !$options.v3
  warn $options.v3_used
  $options.v3_used = nil
  $options.v3 = true
end

if coding_override
  input = input.encode(Encoding.find(coding_override), fallback: FALLBACK)
end

# 1.4.17: because of UTF-8 bibxml files, kramdown always needs to see UTF-8 (!)
if input.encoding != Encoding::UTF_8
  input = input.encode(Encoding::UTF_8)
end

# warn "options: #{options.inspect}"
doc = Kramdown::Document.new(input, options)
$stderr.puts doc.warnings.to_yaml unless doc.warnings.empty?
output = doc.to_rfc2629

if $options.v3_used && !$options.v3
  warn $options.v3_used
  $options.v3 = true
end

if $options.autolink_iref_cleanup
  require 'rexml/document'
  require 'kramdown-rfc/autolink-iref-cleanup'

  d = REXML::Document.new(output)
  autolink_iref_cleanup(d)
  output = d.to_s
end

if coding_override
  output = output.encode(Encoding.find(coding_override), fallback: FALLBACK)
end

puts output
