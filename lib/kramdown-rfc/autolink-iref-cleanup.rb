require 'rexml/document'

def autolink_iref_cleanup(d)

  d.root.get_elements("//section[@anchor]").each do |sec|
    anchor = sec['anchor']
    irefs = {}
    sec.get_elements(".//xref[@target='#{anchor}'][@format='none']").each do |xr|
      ne = xr.next_element
      if ne && ne.name == "iref" && (item = ne['item'])
        irefs[item] = ne['subitem'] # XXX one subitem only
        ne.remove
        chi = xr.children
        chi[1..-1].reverse.each do |ch|
          xr.parent.insert_after(xr, ch)
        end
        xr.replace_with(chi[0])
      end
    end
    irefs.each do |k, v|
      sec.insert_after(sec.get_elements("name").first, 
                       e = REXML::Element.new("iref", sec))
      e.attributes["item"] = k
      e.attributes["subitem"] = v
      e.attributes["primary"] = 'true'
    end
  end

end
