require 'rexml/document'

d = REXML::Document.new(ARGF.read)

REXML::XPath.each(d.root, "//section[@anchor]") do |sec|
  anchor = sec['anchor']
  irefs = {}
  REXML::XPath.each(sec, ".//xref[@target='#{anchor}'][@format='none']") do |xr|
    ne = xr.next_element
    if ne && (item = ne['item'])
      irefs[item] = true
      ne.parent.delete_element(ne)
      chi = xr.children
      chi[1..-1].reverse.each do |ch|
        xr.parent.insert_after(xr, ch)
      end
      xr.replace_with(chi[0])
    end
  end
  irefs.each do |k, v|
    sec.insert_after(REXML::XPath.each(sec, "name").first, 
                     e = REXML::Element.new("iref", sec))
    e.attributes["item"] = k
    e.attributes["primary"] = 'true'
  end
end

puts d.to_s
