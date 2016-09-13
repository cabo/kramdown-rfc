module KramdownRFC

  class ParameterSet
    include Kramdown::Utils::Html

    attr_reader :f
    def initialize(y)
      raise "*** invalid parameter set #{y.inspect}" unless Hash === y
      @f = y
    end
    def [](pn)
      @f.delete(pn.to_s)
    end
    def has(pn)
      @f[pn.to_s]
    end
    def escattr(str)
      escape_html(str.to_s, :attribute)
    end
    def van(pn)                   # pn is a parameter name, possibly with an =alias
      an, pn = pn.to_s.split("=")
      pn ||= an
      [self[pn] || self[an], an]
    end
    def attr(pn)
      val, an = van(pn)
      %{#{an}="#{escattr(val)}"}    if val
    end
    def attrs(*pns)
      pns.map{ |pn| attr(pn) }.compact.join(" ")
    end
    def ele(pn, attr=nil, defcontent=nil)
      val, an = van(pn)
      val ||= defcontent
      Array(val).map do |val1|
        %{<#{[an, *Array(attr).map(&:to_s)].join(" ").strip}>#{escape_html(val1.to_s.strip)}</#{an}>}
      end.join(" ")
    end
    def arr(an, converthash=true, must_have_one=false, &block)
      arr = self[an] || []
      arr = [arr] if Hash === arr && converthash
      arr << { } if must_have_one && arr.empty?
      Array(arr).each(&block)
    end
    def rest
      @f
    end
    def warn_if_leftovers
      if !@f.empty?
        warn "*** attributes left #{@f.inspect}!"
      end
    end
  end

  
end
