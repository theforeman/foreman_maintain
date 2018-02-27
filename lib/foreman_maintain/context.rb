module ForemanMaintain
  class Context
    def initialize(data = {})
      @data = data
      @mapping = {}
    end

    def set(key, value, mapping = {})
      @data[key] = value
      map(key, mapping)
    end

    def get(key, default = nil)
      @data.fetch(key, default)
    end

    def to_hash
      @data
    end

    def map(key, mapping = {})
      @mapping[key] ||= {}
      @mapping[key].merge!(mapping)
    end

    def params_for(definition)
      @mapping.inject({}) do |params, (key, mapping)|
        target = mapping[definition]
        params[target] = @data[key] unless target.nil?
        params
      end
    end
  end
end
