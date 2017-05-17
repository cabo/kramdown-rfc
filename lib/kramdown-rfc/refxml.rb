module KramdownRFC

  extend Kramdown::Utils::Html

  def self.escattr(str)
    escape_html(str.to_s, :attribute)
  end

  def self.ref_to_xml(k, v)
    vps = KramdownRFC::ParameterSet.new(v)
    erb = ERB.new <<-REFERB, nil, '-'
<reference anchor="<%= escattr(k) %>" <%= vps.attr("target") %>>
  <front>
    <%= vps.ele("title") -%>

<% vps.arr("author", true, true) do |au|
   aups = authorps_from_hash(au)
 -%>
    <author <%=aups.attrs("initials", "surname", "fullname=name", "role")%>>
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
</reference>
    REFERB
    ret = erb.result(binding)
    vps.warn_if_leftovers
    ret
  end

  def self.authorps_from_hash(au)
    aups = KramdownRFC::ParameterSet.new(au)
    if ins = aups[:ins]
      parts = ins.split('.').map(&:strip)
      aups.rest["initials"] = parts[0..-2].join('.') << '.'
      aups.rest["surname"] = parts[-1]
    end
    # hack ("heuristic for") initials and surname from name
    # -- only works for people with exactly one last name and uncomplicated first names
    if n = aups.rest["name"]
      n = n.split
      aups.rest["initials"] ||= n[0..-2].map(&:chr).join('.') << '.'
      aups.rest["surname"] ||= n[-1]
    end
    aups
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
