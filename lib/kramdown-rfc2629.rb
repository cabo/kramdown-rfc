# -*- coding: utf-8 -*-
#
#--
# Copyright (C) 2009-2010 Thomas Leitner <t_leitner@gmx.at>
# Copyright (C) 2010-2014 Carsten Bormann <cabo@tzi.org>
#
# This file was derived from a part of the kramdown gem which is licensed under the MIT license.
# This derived work is also licensed under the MIT license, see LICENSE.
#++
#

raise "sorry, 1.8 was last decade" unless RUBY_VERSION >= '1.9'

gem 'kramdown', '~> 1.5.0'
require 'kramdown'

require 'rexml/parsers/baseparser'

class Object
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

module Kramdown

  module Parser
    class RFC2629Kramdown < Kramdown

      def initialize(*doc)
        super
        @span_parsers.unshift(:xref)
      end

      XREF_START = /\{\{(.*?)\}\}/u

      # Introduce new {{target}} syntax for empty xrefs, which would
      # otherwise be an ugly ![!](target) or ![ ](target)
      # (I'd rather use [[target]], but that somehow clashes with links.)
      def parse_xref
        @src.pos += @src.matched_size
        href = @src[1]
        href = href.gsub(/\A[0-9]/) { "_#{$&}" } # can't start an IDREF with a number
        el = Element.new(:xref, nil, {'target' => href})
        @tree.children << el
      end
      define_parser(:xref, XREF_START, '{{')

    end
  end

  class Element
    def rfc2629_fix
      if a = attr
        if anchor = a.delete('id')
          a['anchor'] = anchor
        end
        if anchor = a.delete('href')
          a['target'] = anchor
        end
      end
    end
  end

  module Converter

    # Converts a Kramdown::Document to HTML.
    class Rfc2629 < Base

      # we use these to do XML stuff, too
      include ::Kramdown::Utils::Html

      def el_html_attributes(el)
        html_attributes(el.attr)
      end
      def el_html_attributes_with(el, defattr)
        html_attributes(defattr.merge(el.attr))
      end

      # :stopdoc:

      # Defines the amount of indentation used when nesting XML tags.
      INDENTATION = 2

      # Initialize the XML converter with the given Kramdown document +doc+.
      def initialize(*doc)
        super
        @sec_level = 1
        @in_dt = 0
      end

      def convert(el, indent = -INDENTATION, opts = {})
        if el.children[-1].type == :raw
          raw = convert1(el.children.pop, indent, opts)
        end
        "#{convert1(el, indent, opts)}#{end_sections(1, indent)}#{raw}"
      end

      def convert1(el, indent, opts = {})
        el.rfc2629_fix
        send("convert_#{el.type}", el, indent, opts)
      end

      def inner_a(el, indent, opts)
        indent += INDENTATION
        el.children.map do |inner_el|
          inner_el.rfc2629_fix
          send("convert_#{inner_el.type}", inner_el, indent, opts)
        end
      end

      def inner(el, indent, opts)
        inner_a(el, indent, opts).join('')
      end

      def convert_blank(el, indent, opts)
        "\n"
      end

      def convert_text(el, indent, opts)
        escape_html(el.value, :text)
      end

      def convert_p(el, indent, opts)
        if (el.children.size == 1 && el.children[0].type == :img) || opts[:unpacked]
          inner(el, indent, opts) # Part of the bad reference hack
        else
          "#{' '*indent}<t#{el_html_attributes(el)}>#{inner(el, indent, opts)}</t>\n"
        end
      end

      def saner_generate_id(value)
        generate_id(value).gsub(/-+/, '-')
      end

      def convert_codeblock(el, indent, opts)
        # el.attr['anchor'] ||= saner_generate_id(el.value) -- no longer in 1.0.6
        result = el.value
        blockclass = el.attr.delete('class')
        if blockclass == 'language-tbreak'
          result = result.lines.map {|line| [line.chomp, 0]}
          spaceind = 0
          result.each_with_index {|pair, index|
            if pair[0] == ''
              result[spaceind][1] += 1
              pair[0] = nil unless index == spaceind
            else
              spaceind = index
            end
          }
          # $stderr.puts(result.inspect)
          result = result.map {|line, space|
            "<![CDATA[#{line.gsub(/^\s+/) {|s| "\u00A0" * s.size}}]]><vspace blankLines=\"#{space}\"/>" if line
          }.compact.join("\n")
          "#{' '*indent}<t>#{result}</t>\n"
        else
          if blockclass
            $stderr.puts "*** Unimplemented block class: #{blockclass}"
          end
          # compensate for XML2RFC idiosyncracy by insisting on a blank line
          unless el.attr.delete('tight')
            result[0,0] = "\n" unless result[0,1] == "\n"
          end
          "#{' '*indent}<figure#{el_html_attributes(el)}><artwork><![CDATA[#{result}#{result =~ /\n\Z/ ? '' : "\n"}]]></artwork></figure>\n"
        end
      end

      def convert_blockquote(el, indent, opts)
        "#{' '*indent}<t><list style='empty'#{el_html_attributes(el)}>\n#{inner(el, indent, opts)}#{' '*indent}</list></t>\n"
      end

      def end_sections(to_level, indent)
        if indent < 0
          indent = 0
        end
        if @sec_level >= to_level
          delta = (@sec_level - to_level)
          @sec_level = to_level
          "#{' '*indent}</section>\n" * delta
        else
          $stderr.puts "Incorrect section nesting: Need to start with 1"
        end
      end

      def convert_header(el, indent, opts)
        # todo: handle appendix tags
        el = el.deep_clone
        options = @doc ? @doc.options : @options # XXX: 0.11 vs. 0.12
        if options[:auto_ids] && !el.attr['anchor']
          el.attr['anchor'] = saner_generate_id(el.options[:raw_text])
        end
        el.attr['title'] = inner(el, indent, opts)
        "#{end_sections(el.options[:level], indent)}#{' '*indent}<section#{@sec_level += 1; el_html_attributes(el)}>\n"
      end

      def convert_hr(el, indent, opts) # misuse for page break
        "#{' '*indent}<t><vspace blankLines='999' /></t>\n"
      end

      STYLES = {ul: 'symbols', ol: 'numbers', dl: 'hanging'}

      def convert_ul(el, indent, opts)
        opts = opts.merge(vspace: el.attr.delete('vspace'))
        attrstring = el_html_attributes_with(el, {"style" => STYLES[el.type]})
        if opts[:unpacked]
          "#{' '*indent}<list#{attrstring}>\n#{inner(el, indent, opts)}#{' '*indent}</list>\n"
          else
          "#{' '*indent}<t><list#{attrstring}>\n#{inner(el, indent, opts)}#{' '*indent}</list></t>\n"
        end
      end
      alias :convert_ol :convert_ul
      alias :convert_dl :convert_ul

      def convert_li(el, indent, opts)
        res_a = inner_a(el, indent, opts)
        if el.children.empty? || el.children.first.options[:category] == :span
          res = res_a.join('')
        else                    # merge multiple <t> elements
          res = res_a.select { |x|
            x.strip != ''
          }.map { |x|
            x.sub(/\A\s*<t>(.*)<\/t>\s*\Z/m) { $1}
          }.join("#{' '*indent}<vspace blankLines='1'/>\n").gsub(%r{(</list>)\s*<vspace blankLines='1'/>}) { $1 }.gsub(%r{<vspace blankLines='1'/>\s*(<list)}) { $1 }
        end
        "#{' '*indent}<t#{el_html_attributes(el)}>#{res}#{(res =~ /\n\Z/ ? ' '*indent : '')}</t>\n"
      end
      def convert_dd(el, indent, opts)
        output = ' '*indent
        if @in_dt == 1
          @in_dt = 0
        else
          output << "<t#{el_html_attributes(el)}>"
        end
        res = inner(el, indent+INDENTATION, opts.merge(unpacked: true))
#        if el.children.empty? || el.children.first.options[:category] != :block
          output << res << (res =~ /\n\Z/ ? ' '*indent : '')
#        else                    FIXME: The latter case is needed for more complex cases
#          output << "\n" << res << ' '*indent
#        end
        output << "</t>\n"
      end

      def convert_dt(el, indent, opts) # SERIOUSLY BAD HACK:
        close = "#{' '*indent}</t>\n" * @in_dt
        @in_dt = 1
        vspace = opts[:vspace]
        vspaceel = "<vspace blankLines='#{vspace}'/>" if vspace
        "#{close}#{' '*indent}<t#{el_html_attributes(el)} hangText='#{inner(el, indent, opts)}'>#{vspaceel}\n"
      end

      HTML_TAGS_WITH_BODY=['div', 'script']

      def convert_html_element(el, indent, opts)
        res = inner(el, indent, opts)
        if el.options[:category] == :span
          "<#{el.value}#{el_html_attributes(el)}" << (!res.empty? ? ">#{res}</#{el.value}>" : " />")
        else
          output = ''
          output << ' '*indent if !el.options[:parent_is_raw]
          output << "<#{el.value}#{el_html_attributes(el)}"
          if !res.empty? && el.options[:parse_type] != :block
            output << ">#{res}</#{el.value}>"
          elsif !res.empty?
            output << ">\n#{res}"  << ' '*indent << "</#{el.value}>"
          elsif HTML_TAGS_WITH_BODY.include?(el.value)
            output << "></#{el.value}>"
          else
            output << " />"
          end
          output << "\n" if el.options[:outer_element] || !el.options[:parent_is_raw]
          output
        end
      end

      def convert_xml_comment(el, indent, opts)
        if el.options[:category] == :block && !el.options[:parent_is_raw]
          ' '*indent + el.value + "\n"
        else
          el.value
        end
      end
      alias :convert_xml_pi :convert_xml_comment
      alias :convert_html_doctype :convert_xml_comment

      ALIGNMENTS = { default: :left, left: :left, right: :right, center: :center}
      COLS_ALIGN = { "l" => :left, "c" => :center, "r" => :right}

      def convert_table(el, indent, opts) # This only works for tables with headers
        alignment = el.options[:alignment].map { |al| ALIGNMENTS[al]}
        cols = (el.attr.delete("cols") || "").split(' ')
        "#{' '*indent}<texttable#{el_html_attributes(el)}>\n#{inner(el, indent, opts.merge(table_alignment: alignment, table_cols: cols))}#{' '*indent}</texttable>\n"
      end

      def convert_thead(el, indent, opts)
        inner(el, indent, opts)
      end
      alias :convert_tbody :convert_thead
      alias :convert_tfoot :convert_thead
      alias :convert_tr  :convert_thead

      def convert_td(el, indent, opts)
        if alignment = opts[:table_alignment]
          alignment = alignment.shift
          if cols = opts[:table_cols].shift
            md = cols.match(/(\d*(|em|[%*]))([lrc])/)
            if md[1].to_i != 0
              widthval = md[1]
              widthval << "em" if md[2].empty?
              widthopt = "width='#{widthval}' "
            end
            alignment = COLS_ALIGN[md[3]] || :left
          end
        end
        res = inner(el, indent, opts)
        if alignment
          "#{' '*indent}<ttcol #{widthopt}align='#{alignment}'#{el_html_attributes(el)}>#{res.empty? ? "&#160;" : res}</ttcol>\n"
          else
          "#{' '*indent}<c#{el_html_attributes(el)}>#{res.empty? ? "&#160;" : res}</c>\n"
        end
      end
      alias :convert_th :convert_td

      def convert_comment(el, indent, opts)
## Don't actually output all those comments into the XML:
#        if el.options[:category] == :block
#          "#{' '*indent}<!-- #{el.value} -->\n"
#        else
#          "<!-- #{el.value} -->"
#        end
      end

      def convert_br(el, indent, opts)
        "<vspace />"
      end

      def convert_a(el, indent, opts)
        res = inner(el, indent, opts)
        target = el.attr['target']
        if target[0] == "#"     # handle [](#foo) as xref as in RFC 7328
          el.attr['target'] = target = target[1..-1]
          if target.downcase == res.downcase
            res = ''            # get rid of raw anchors leaking through
          end
          "<xref#{el_html_attributes(el)}>#{res}</xref>"
        else
          "<eref#{el_html_attributes(el)}>#{res}</eref>"
        end
      end

      def convert_xref(el, indent, opts)
        target = el.attr['target']
        if target[0] == "&"
          "#{target};"
        else
          "<xref#{el_html_attributes(el)}/>"
        end
      end

      REFCACHEDIR = ".refcache"
      def get_and_cache_resource(url, tn = Time.now, tvalid = 7200)
        Dir.mkdir(REFCACHEDIR) unless Dir.exists?(REFCACHEDIR)
        fn = "#{REFCACHEDIR}/#{File.basename(url)}"
        f = File.stat(fn) rescue nil
        if !f || tn - f.ctime >= tvalid
          $stderr.puts "#{fn}: #{f && "renewing (stale by #{"%.1f" % ((tn-f.ctime)/86400)} days)" || "fetching"}"
          if ENV["HAVE_WGET"]
            `cd #{REFCACHEDIR}; wget -t 3 -T 20 -Nnv "#{url}"` # ignore errors if offline (hack)
            begin
              File.utime nil, nil, fn
            rescue Errno::ENOENT
              warn "Can't fetch #{url} -- is wget in path?"
            end
          else
            require 'open-uri'
            require 'timeout'
            begin
              Timeout::timeout(f ? 10 : 30) do # give up quickly if just renewing
                open(url) do |f|
                  s = f.read
                  if f.status[0] != "200"
                    warn "*** Status code #{status} while fetching #{url}"
                  else
                    File.write(fn, s)
                  end
                end
              end
            rescue OpenURI::HTTPError, SocketError, Timeout::Error => e
              warn "*** #{e} while fetching #{url}"
            end
          end
        end
        File.read(fn) # this blows up if no cache available after fetch attempt
      end

      XML_RESOURCE_ORG_MAP = {
        "RFC" => "bibxml", "I-D" => "bibxml3", "W3C" => "bibxml4", "3GPP" => "bibxml5",
        "ANSI" => "bibxml2",
        "CCITT" => "bibxml2",
        "FIPS" => "bibxml2",
        "IANA" => "bibxml2",
        "IEEE" => "bibxml2",
        "ISO" => "bibxml2",
        "ITU" => "bibxml2",
        "NIST" => "bibxml2",
        "OASIS" => "bibxml2",
        "PKCS" => "bibxml2",
      }

      # XML_RESOURCE_ORG_HOST = ENV["XML_RESOURCE_ORG_HOST"] || "xml.resource.org"
      XML_RESOURCE_ORG_HOST = ENV["XML_RESOURCE_ORG_HOST"] || "xml2rfc.tools.ietf.org"
      XML_RESOURCE_ORG_PREFIX = ENV["XML_RESOURCE_ORG_PREFIX"] ||
                                "http://#{XML_RESOURCE_ORG_HOST}/public/rfc"

      def convert_img(el, indent, opts) # misuse the tag!
        if a = el.attr
          alt = a.delete('alt').strip
          alt = '' if alt == '!' # work around re-wrap uglyness
          if anchor = a.delete('src')
            a['target'] = anchor
          end
        end
        if alt == ":include:"   # Really bad misuse of tag...
          to_insert = ""
          anchor.scan(/(W3C|3GPP|[A-Z-]+)[.]?([A-Za-z0-9.-]+)/) do |t, n|
            fn = "reference.#{t}.#{n}.xml"
            sub = XML_RESOURCE_ORG_MAP[t]
            puts "Huh: ${fn}" unless sub
            url = "#{XML_RESOURCE_ORG_PREFIX}/#{sub}/#{fn}"
            to_insert = get_and_cache_resource(url)
          end
          to_insert.gsub(/<\?xml version=["']1.0["'] encoding=["']UTF-8["']\?>/, '').
            gsub(/(anchor=["'])([0-9])/) { "#{$1}_#{$2}"} # can't start an ID with a number
        else
          "<xref#{el_html_attributes(el)}>#{alt}</xref>"
        end
      end

      def convert_codespan(el, indent, opts)
        attrstring = el_html_attributes_with(el, {"style" => 'verb'})
        "<spanx#{attrstring}>#{escape_html(el.value)}</spanx>"
      end

      def convert_footnote(el, indent, opts) # XXX: footnotes into crefs???
        # this would be more like xml2rfc v3:
        # "\n#{' '*indent}<cref>\n#{inner(el.value, indent, opts).rstrip}\n#{' '*indent}</cref>"
        content = inner(el.value, indent, opts).strip
        content = escape_html(content.sub(/\A<t>(.*)<\/t>\z/m) {$1}, :text) # text only...
        name = el.options[:name].sub(/\A[0-9]/) {"_" << $&}
        attrstring = el_html_attributes_with(el, {"anchor" => name})
        "\n#{' '*indent}<cref#{attrstring}>#{content}</cref>"
      end

      def convert_raw(el, indent, opts)
        end_sections(1, indent) +
        el.value + (el.options[:category] == :block ? "\n" : '')
      end

      EMPH = { em: "emph", strong: "strong"}

      def convert_em(el, indent, opts)
        attrstring = el_html_attributes_with(el, {"style" => EMPH[el.type]})
        "<spanx#{attrstring}>#{inner(el, indent, opts)}</spanx>"
      end
      alias :convert_strong :convert_em

      def convert_entity(el, indent, opts)
        entity_to_str(el.value)
      end

      TYPOGRAPHIC_SYMS = {
        :mdash => [::Kramdown::Utils::Entities.entity('mdash')],
        :ndash => [::Kramdown::Utils::Entities.entity('ndash')],
        :hellip => [::Kramdown::Utils::Entities.entity('hellip')],
        :laquo_space => [::Kramdown::Utils::Entities.entity('laquo'), ::Kramdown::Utils::Entities.entity('nbsp')],
        :raquo_space => [::Kramdown::Utils::Entities.entity('nbsp'), ::Kramdown::Utils::Entities.entity('raquo')],
        :laquo => [::Kramdown::Utils::Entities.entity('laquo')],
        :raquo => [::Kramdown::Utils::Entities.entity('raquo')]
      }
      def convert_typographic_sym(el, indent, opts)
        TYPOGRAPHIC_SYMS[el.value].map {|e| entity_to_str(e)}.join('')
      end

      def convert_smart_quote(el, indent, opts)
        entity_to_str(::Kramdown::Utils::Entities.entity(el.value.to_s))
      end

      def convert_math(el, indent, opts) # XXX: This is wrong
        el = el.deep_clone
        el.attr['class'] ||= ''
        el.attr['class'] += (el.attr['class'].empty? ? '' : ' ') + 'math'
        type = 'span'
        type = 'div' if el.options[:category] == :block
        "<#{type}#{el_html_attributes(el)}>#{escape_html(el.value, :text)}</#{type}>#{type == 'div' ? "\n" : ''}"
      end

      def convert_abbreviation(el, indent, opts) # XXX: This is wrong
        title = @root.options[:abbrev_defs][el.value]
        title = nil if title.empty?
        value = el.value
        "#{el.value}<iref #{title ? "item=\"#{title}\" sub" : ''}item=\"#{value}\"/>"
      end

      def convert_root(el, indent, opts)
        result = inner(el, indent, opts)
      end

    end

  end
end
