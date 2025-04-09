require 'yaml'

module KramdownRFC
  module YAMLcheck

    def self.short_name(node)
      if node.scalar?
        node.value
      else
        node.children&.map {|nm| short_name(nm)}&.join("_")
      end
    end

    # Does not follow aliases.
    def self.check_dup_keys1(node, path)
      if YAML::Nodes::Mapping === node
        children = node.children.each_slice(2)
        duplicates = children.map { |key_node, _value_node|
          key_node }.group_by{|nm| short_name(nm)}.select { |_value, nodes| nodes.size > 1 }

        duplicates.each do |key, nodes|
          name = (path + [key]).join("/")
          lines = nodes.map { |occurrence| occurrence.start_line + 1 }.join(", ")
          warn "** duplicate map key >#{name}< in YAML, lines #{lines}"
        end

        children.each do |key_node, value_node|
          newname = short_name(key_node)
          check_dup_keys1(value_node, path + Array(newname))
        end
      else
        node.children.to_a.each { |child| check_dup_keys1(child, path) }
      end
    end

    def self.check_dup_keys(data)
      ast = YAML.parse_stream(data)
      check_dup_keys1(ast, [])
    end

    # check_dup_keys(DATA)

  end
end
