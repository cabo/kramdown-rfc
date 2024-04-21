require 'rexml/document'

module REXML
  # all_text: Get all text from descendants that are Text or CData
  class Element
    def all_text
      @children.map {|c| c.all_text}.join
    end
  end
  class Text                    # also: ancestor of CData
    def all_text
      value
    end
  end
  class Child
    def all_text
      ''
    end
  end
end
