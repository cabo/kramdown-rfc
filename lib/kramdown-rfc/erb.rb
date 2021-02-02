require 'erb'

class ERB

  case version.sub("erb.rb [", "")
  when /\A2.1/                    # works back to 1.9.1
    def self.trim_new(s, trim)
      ERB.new(s, nil, trim)
    end
  else
    def self.trim_new(s, trim)
      ERB.new(s, trim_mode: trim)
    end
  end

end
