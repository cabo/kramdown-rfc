module KramdownRFC

  class ParameterSet
    include Kramdown::Utils::Html

    attr_reader :f
    def initialize(y)
      raise "*** invalid parameter set #{y.inspect}" unless Hash === y
      @f = y
      @av = {}
    end
    attr :av
    def [](pn)
      @f.delete(pn.to_s)
    end
    def []=(pn, val)
      @f[pn.to_s] = val
    end
    def default(pn, &block)
      @f.fetch(pn.to_s, &block)
    end
    def default!(pn, value)
      default(pn) {
        @f[pn.to_s] = value
      }
    end
    def has(pn)
      @f[pn.to_s]
    end
    def has?(pn)
      @f.key?(pn.to_s)
    end
    def escattr(str)
      escape_html(str.to_s, :attribute)
    end
    def van(pn)         # pn is a parameter name, possibly with =aliases
      names = pn.to_s.split("=")
      [self[names.reverse.find{|nm| has?(nm)}], names.first]
    end
    def attr(pn)
      val, an = van(pn)
      @av[an.intern] = val
      %{#{an}="#{escattr(val)}"}    if val # see attrtf below
    end
    def attrs(*pns)
      pns.map{ |pn| attr(pn) if pn }.compact.join(" ")
    end
    def attrtf(pn)              # can do an overriding false value
      val, an = van(pn)
      @av[an.intern] = val
      %{#{an}="#{escattr(val)}"}    unless val.nil?
    end
    def attrstf(*pns)
      pns.map{ |pn| attrtf(pn) if pn }.compact.join(" ")
    end
    def ele(pn, attr=nil, defcontent=nil, markdown=false)
      val, an = van(pn)
      val ||= defcontent
      val = [val] if Hash === val
      Array(val).map do |val1|
        a = Array(attr).dup
        if Hash === val1
          val1.each do |k, v|
            if k == ":"
              val1 = v
            else
              k = Kramdown::Element.attrmangle(k) || k
              a.unshift(%{#{k}="#{escattr(v)}"})
            end
          end
        end
        v = val1.to_s.strip
        contents =
          if markdown
            ::Kramdown::Converter::Rfc2629::process_markdown(v)
          else
            escape_html(v)
          end
        %{<#{[an, *a.map(&:to_s)].join(" ").strip}>#{contents}</#{an}>}
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
