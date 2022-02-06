require 'kramdown-rfc/erb'

module KramdownRFC

  extend Kramdown::Utils::Html

  def self.escattr(str)
    escape_html(str.to_s, :attribute)
  end

  AUTHOR_ATTRIBUTES = %w{
    initials surname fullname
    asciiInitials asciiSurname asciiFullname
    role
  }

  def self.ref_to_xml(k, v)
    vps = KramdownRFC::ParameterSet.new(v)
    erb = ERB.trim_new <<-REFERB, '-'
<reference anchor="<%= escattr(k) %>" <%= vps.attr("target") %>>
  <front>
    <%= vps.ele("title") -%>

<% vps.arr("author", true, true) do |au|
   aups = authorps_from_hash(au)
 -%>
    <author <%=aups.attrs(*AUTHOR_ATTRIBUTES)%>>
      <%= aups.ele("organization=org", aups.attr("abbrev=orgabbrev"), "") %>
    </author>
<%   aups.warn_if_leftovers  -%>
<% end -%>
    <date <%= dateattrs(vps[:date]) %>/>
  </front>
<% vps.arr("seriesinfo", false) do |k, v| -%>
  <seriesInfo name="<%=escattr(k)%>" value="<%=escattr(v)%>"/>
<% end -%>
<% vps.arr("format", false) do |k, v| -%>
  <format type="<%=escattr(k)%>" target="<%=escattr(v)%>"/>
<% end -%>
<%= vps.ele("annotation=ann", nil, nil, true) -%>
<%= vps.ele("refcontent=rc", nil, nil, true) -%>
</reference>
    REFERB
    ret = erb.result(binding)
    vps.warn_if_leftovers
    ret
  end

  def self.treat_multi_attribute_member(ps, an)
    value = ps.rest[an]
    if Hash === value
      value.each do |k, v|
        ps.rest[if k == ':'
                  an
                else
                  Kramdown::Element.attrmangle(k + an) ||
                  Kramdown::Element.attrmangle(k) ||
                  k
                end] = v
      end
    end
  end

  def self.initializify(s)      # XXX Jean-Pierre
    w = '\p{Lu}\p{Lo}'
    if s =~ /\A[-.#{w}]+[.]/u
      $&
    elsif s =~ /\A([#{w}])[^-]*/u
      ret = "#$1."
      while (s = $') && s =~ /\A(-[\p{L}])[^-]*/u
        ret << "#$1."
      end
      ret
    else
      warn "*** Can't initializify #{s}"
      s
    end
  end

  def self.looks_like_initial(s)
    s =~ /\A[\p{Lu}\p{Lo}]([-.][\p{Lu}\p{Lo}]?)*\z/u
  end

  def self.initials_from_parts_and_surname(aups, parts, s)
    ssz = s.size
    nonsurname = parts[0...-ssz]
    if (ns = parts[-ssz..-1]) != s
      warn "*** inconsistent surnames #{ns} and #{s}"
    end
    nonsurname.map{|x| initializify(x)}.join(" ")
  end

  def self.handle_ins(aups, ins_k, initials_k, surname_k)
    if ins = aups[ins_k]
      parts = ins.split('.').map(&:strip) # split on dots first
      # Coalesce H.-P.
      i = 1; while i < parts.size
        if parts[i][0] == "-"
          parts[i-1..i] = [parts[i-1] + "." + parts[i]]
        else
          i += 1
        end
      end
      # Multiple surnames in ins?
      parts[-1..-1] = parts[-1].split
      s = if surname = aups.rest[surname_k]
            surname.split
          else parts.reverse.take_while{|x| !looks_like_initial(x)}.reverse
          end
      aups.rest[initials_k] = initials_from_parts_and_surname(aups, parts, s)
      aups.rest[surname_k] = s.join(" ")
    end
  end

  def self.handle_name(aups, fn_k, initials_k, surname_k)
    if name = aups.rest[fn_k]
      names = name.split(/ *\| */, 2) # boundary for given/last name
      if names[1]
        aups.rest[fn_k] = name = names.join(" ") # remove boundary
        if surname = aups.rest[surname_k]
          if surname != names[1]
            warn "*** inconsistent embedded surname #{names[1]} and surname #{surname}"
          end
        end
        aups.rest[surname_k] = names[1]
      end
      parts = name.split
      surname = aups.rest[surname_k] || parts[-1]
      s = surname.split
      aups.rest[initials_k] ||= initials_from_parts_and_surname(aups, parts, s)
      aups.rest[surname_k] = s.join(" ")
    end
  end

  def self.authorps_from_hash(au)
    aups = KramdownRFC::ParameterSet.new(au)
    if n = aups[:name]
      warn "** both name #{n} and fullname #{fn} are set on one author" if fn = aups.rest["fullname"]
      aups.rest["fullname"] = n
      usename = true
    end
    ["fullname", "ins", "initials", "surname"].each do |an|
      treat_multi_attribute_member(aups, an)
    end
    handle_ins(aups, :ins, "initials", "surname")
    handle_ins(aups, :asciiIns, "asciiInitials", "asciiSurname")
    # hack ("heuristic for") initials and surname from name
    # -- only works for people with exactly one last name and uncomplicated first names
    # -- add surname for people with more than one last name
    if usename
      handle_name(aups, "fullname", "initials", "surname")
      handle_name(aups, "asciiFullname", "asciiInitials", "asciiSurname")
    end
    aups
  end

  # The below anticipates the "postalLine" changes.
  # If a postalLine is used (abbreviated "postal" in YAML),
  # non-postalLine elements are appended as further postalLines.
  # This prepares for how "country" is expected to be handled
  # specially with the next schema update.
  # So an address is now best keyboarded as:
  #   postal:
  #     - Foo Street
  #     - 28359 Bar
  #   country: Germany

  PERSON_ERB = <<~ERB
    <<%= element_name%> <%=aups.attrs(*AUTHOR_ATTRIBUTES)%>>
      <%= aups.ele("organization=org", aups.attrs("abbrev=orgabbrev",
                                                  *[$options.v3 && "ascii=orgascii"]), "") %>
      <address>
<% postal_elements = %w{extaddr pobox street cityarea city region code sortingcode country postal}.select{|gi| aups.has(gi)}
   if postal_elements != [] -%>
        <postal>
<% if pl = postal_elements.delete("postal") -%>
          <%= aups.ele("postalLine=postal") %>
<%   postal_elements.each do |gi| -%>
          <%= aups.ele("postalLine=" << gi) %>
<%   end -%>
<% else -%>
<%   postal_elements.each do |gi| -%>
          <%= aups.ele(gi) %>
<%   end -%>
<% end -%>
        </postal>
<% end -%>
<% %w{phone facsimile email uri}.select{|gi| aups.has(gi)}.each do |gi| -%>
        <%= aups.ele(gi) %>
<% end -%>
      </address>
    </<%= element_name%>>
  ERB

  def self.person_element_from_aups(element_name, aups)
    erb = ERB.trim_new(PERSON_ERB, '-')
    erb.result(binding)
  end

  def self.dateattrs(date)
    begin
      case date
      when /\A\d\d\d\d\z/
        %{year="#{date}"}
      when Integer
        %{year="#{"%04d" % date}"}
      when String
        Date.parse("#{date}-01").strftime(%{year="%Y" month="%B"})
      when Date
        date.strftime(%{year="%Y" month="%B" day="%d"})
      when Array                  # this allows to explicitly give a string
        %{year="#{date.join(" ")}"}
      when nil
        %{year="n.d."}
      end

    rescue ArgumentError
      warn "*** Invalid date: #{date} -- use 2012, 2012-07, or 2012-07-28"
    end
  end
end
