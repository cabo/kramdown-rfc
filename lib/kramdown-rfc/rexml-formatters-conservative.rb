require 'rexml/document'

module REXML
  module Formatters
    # The Conservative formatter writes an XML document that parses to an
    # identical document as the source document.  This means that no extra
    # whitespace nodes are inserted, and whitespace within text nodes is
    # preserved.  Attributes are not sorted.
    class Conservative < Default
      def initialize
        @indentation = 0
        @level = 0
        @ie_hack = false
      end

      protected
      def write_element( node, output )
        output << "<#{node.expanded_name}"

        node.attributes.each_attribute do |attr|
          output << " "
          attr.write( output )
        end unless node.attributes.empty?

        if node.children.empty?
          output << "/"
        else
          output << ">"
          node.children.each { |child|
            write( child, output )
          }
          output << "</#{node.expanded_name}"
        end
        output << ">"
      end
    end
  end
end
