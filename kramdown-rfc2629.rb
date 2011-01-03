# -*- coding: utf-8 -*-
#
#--
# Copyright (C) 2010 Carsten Bormann <cabo@tzi.org>
#
# This file is designed to work with kramdown.
# License: GPLv3, unfortunately (look it up).
# Any code that I haven't stolen from kramdown is also licensed under
# the 2-clause BSD license (look it up).
#++
#

raise "sorry, 1.8 was last decade" unless RUBY_VERSION >= '1.9'

require 'rexml/parsers/baseparser'

class Object
  def deep_clone
    Marshal.load(Marshal.dump(self))
  end
end

module Kramdown

  module Parser
    class RFC2629Kramdown < Kramdown

      def initialize(doc)
        super(doc)
        @span_parsers.unshift(:xref)
      end

      XREF_START = /\{\{(.*?)\}\}/u

      # Introduce new {{target}} syntax for empty xrefs, which would
      # otherwise be an ugly ![!](target) or ![ ](target)
      # (I'd rather use [[target]], but that somehow clashes with links.)
      def parse_xref
        @src.pos += @src.matched_size
        href = @src[1]
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
      include ::Kramdown::Utils::HTML

      # :stopdoc:

      # Defines the amount of indentation used when nesting XML tags.
      INDENTATION = 2

      # Initialize the XML converter with the given Kramdown document +doc+.
      def initialize(doc)
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
          "#{' '*indent}<t#{html_attributes(el)}>#{inner(el, indent, opts)}</t>\n"
        end
      end

      def saner_generate_id(value)
        generate_id(value).gsub(/-+/, '-')
      end

      def convert_codeblock(el, indent, opts)
        el.attr['anchor'] ||= saner_generate_id(el.value)
        result = el.value
        # compensate for XML2RFC idiosyncracy by insisting on a blank line
        unless el.attr.delete('tight')
          result[0,0] = "\n" unless result[0,1] == "\n"
        end
        "#{' '*indent}<figure#{html_attributes(el)}><artwork><![CDATA[#{result}#{result =~ /\n\Z/ ? '' : "\n"}]]></artwork></figure>\n"
      end

      def convert_blockquote(el, indent, opts)
        "#{' '*indent}<t><list style='empty'#{html_attributes(el)}>\n#{inner(el, indent, opts)}#{' '*indent}</list></t>\n"
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
        if @doc.options[:auto_ids] && !el.attr['anchor']
          el.attr['anchor'] = saner_generate_id(el.options[:raw_text])
        end
        el.attr['title'] = inner(el, indent, opts)
        "#{end_sections(el.options[:level], indent)}#{' '*indent}<section#{@sec_level += 1; html_attributes(el)}>\n"
      end

      def convert_hr(el, indent, opts) # misuse for page break
        "#{' '*indent}<t><vspace blankLines='999' /></t>\n"
      end

      STYLES = {ul: 'symbols', ol: 'numbers', dl: 'hanging'}

      def convert_ul(el, indent, opts)
        style = STYLES[el.type]
        "#{' '*indent}<t><list style='#{style}'#{html_attributes(el)}>\n#{inner(el, indent, opts)}#{' '*indent}</list></t>\n"
      end
      alias :convert_ol :convert_ul
      alias :convert_dl :convert_ul

      def convert_li(el, indent, opts)
        res_a = inner_a(el, indent, opts)
        if el.children.empty? || el.children.first.options[:category] != :block
          res = res_a.join('')
        else                    # merge multiple <t> elements
          res = res_a.select { |x|
            x.strip != ''
          }.map { |x|
            x.sub(/\A\s*<t>(.*)<\/t>\s*\Z/m) { $1}
          }.join("#{' '*indent}<vspace blankLines='1'/>\n").gsub(%r{(</list>)\s*<vspace blankLines='1'/>}) { $1 }.gsub(%r{<vspace blankLines='1'/>\s*(<list)}) { $1 }
        end
        "#{' '*indent}<t#{html_attributes(el)}>#{res}#{(res =~ /\n\Z/ ? ' '*indent : '')}</t>\n"
      end
      def convert_dd(el, indent, opts)
        output = ' '*indent
        if @in_dt == 1
          @in_dt = 0
        else
          output << "<t#{html_attributes(el)}>"
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
        "#{close}#{' '*indent}<t#{html_attributes(el)} hangText='#{inner(el, indent, opts)}'>\n"
      end

      HTML_TAGS_WITH_BODY=['div', 'script']

      def convert_html_element(el, indent, opts)
        res = inner(el, indent, opts)
        if el.options[:category] == :span
          "<#{el.value}#{html_attributes(el)}" << (!res.empty? ? ">#{res}</#{el.value}>" : " />")
        else
          output = ''
          output << ' '*indent if !el.options[:parent_is_raw]
          output << "<#{el.value}#{html_attributes(el)}"
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

      def convert_table(el, indent, opts) # This only works for tables with headers
        alignment = el.options[:alignment].map { |al| ALIGNMENTS[al]}
        "#{' '*indent}<texttable#{html_attributes(el)}>\n#{inner(el, indent, opts.merge(table_alignment: alignment))}#{' '*indent}</texttable>\n"
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
        end
        res = inner(el, indent, opts)
        if alignment
          "#{' '*indent}<ttcol align='#{alignment}'#{html_attributes(el)}>#{res.empty? ? "&#160;" : res}</ttcol>\n"
          else
          "#{' '*indent}<c#{html_attributes(el)}>#{res.empty? ? "&#160;" : res}</c>\n"
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
        "<br />"
      end

      def convert_a(el, indent, opts)
        do_obfuscation = el.attr['href'] =~ /^mailto:/
        if do_obfuscation
          el = el.deep_clone
          href = obfuscate(el.attr['href'].sub(/^mailto:/, ''))
          mailto = obfuscate('mailto')
          el.attr['href'] = "#{mailto}:#{href}"
        end
        res = inner(el, indent, opts)
        res = obfuscate(res) if do_obfuscation
        "<eref#{html_attributes(el)}>#{res}</eref>"
      end

      def convert_xref(el, indent, opts)
        "<xref#{html_attributes(el)}/>"
      end

      def convert_img(el, indent, opts) # misuse the tag!
        if a = el.attr
          alt = a.delete('alt').strip
          alt = '' if alt == '!' # work around re-wrap uglyness
          if anchor = a.delete('src')
            a['target'] = anchor
          end
        end
        if alt == ":include:"   # Really bad misuse of tag...
          tn = Time.now
          fn = "/dev/null"
          anchor.scan(/([A-Z-]+)[.]?([a-z0-9-]+)/) do |t, n|
            fn = "reference.#{t}.#{n}.xml"
            sub = { "RFC" => "bibxml", "I-D" => "bibxml3" }[t]
            puts "Huh: ${fn}" unless sub
            url = "http://xml.resource.org/public/rfc/#{sub}/#{fn}"
            f = File.stat(fn) rescue nil
            if !f || tn - f.ctime >= 7200
              $stderr.puts "#{fn}: #{f && tn-f.ctime}"
              `wget -Nnv "#{url}"` # ignore errors if offline (hack)
              File.utime nil, nil, fn
            end
            # puts url, f && tn - f.ctime
          end
          File.read(fn).gsub(/<\?xml version='1.0' encoding='UTF-8'\?>/, '')
        else
          "<xref#{html_attributes(el)}>#{alt}</xref>"
        end
      end

      def convert_codespan(el, indent, opts)
        "<spanx style='verb'#{html_attributes(el)}>#{escape_html(el.value)}</spanx>"
      end

      def convert_footnote(el, indent, opts) # XXX: This is wrong.
        "<xref target='#{escape_html(el.value)}'#{html_attributes(el)}/>"
      end

      def convert_raw(el, indent, opts)
        end_sections(1, indent) +
        el.value + (el.options[:category] == :block ? "\n" : '')
      end

      EMPH = { em: "emph", strong: "strong"}

      def convert_em(el, indent, opts)
        "<spanx style='#{EMPH[el.type]}'#{html_attributes(el)}>#{inner(el, indent, opts)}</spanx>"
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
        "<#{type}#{html_attributes(el)}>#{escape_html(el.value, :text)}</#{type}>#{type == 'div' ? "\n" : ''}"
      end

      def convert_abbreviation(el, indent, opts) # XXX: This is wrong
        title = @doc.parse_infos[:abbrev_defs][el.value]
        title = nil if title.empty?
        "<abbr#{title ? " title=\"#{title}\"" : ''}>#{el.value}</abbr>"
      end

      def convert_root(el, indent, opts)
        result = inner(el, indent, opts)
      end

      # Helper method for obfuscating the +text+ by using XML entities.
      def obfuscate(text)
        result = ""
        text.each_byte do |b|
          result += (b > 128 ? b.chr : "&#%03d;" % b)
        end
        result.force_encoding(text.encoding) if RUBY_VERSION >= '1.9'
        result
      end

    end

  end
end
