require 'rexml/document'

SVG_NAMESPACES = {"svg"=>"http://www.w3.org/2000/svg",
                  "xlink"=>"http://www.w3.org/1999/xlink"}

def svg_id_cleanup(d)
  gensym = "gensym000"

  REXML::XPath.each(d.root, "//svg:svg", SVG_NAMESPACES) do |x|
    gensym = gensym.succ
    # warn "*** SVG"
    # warn "*** SVG: #{x.to_s.size}"
    found_as_id = Set[]
    found_as_href = Set[]
    REXML::XPath.each(x, ".//*[@id]", SVG_NAMESPACES) do |y|
      # warn "*** ID: #{y}"
      name = y.attributes["id"]
      if found_as_id === name
        warn "*** duplicate ID #{name}"
      end
      found_as_id.add(name)
      y.attributes["id"] = "#{name}-#{gensym}"
    end
    REXML::XPath.each(x, ".//*[@xlink:href]", SVG_NAMESPACES) do |y|
      # warn "*** HREF: #{y}"
      name = y.attributes["href"]
      name1 = name[1..-1]
      if !found_as_id === name1
        warn "*** unknown HREF #{name}"
      end
      found_as_href.add(name1)
      y.attributes["xlink:href"] = "#{name}-#{gensym}"
    end
    found_as_id -= found_as_href
    warn "*** warning: unused ID: #{found_as_id.to_a.join(", ")}" unless found_as_id.empty?
  end
rescue => detail
  warn "*** Can't clean SVG: #{detail}"
end
