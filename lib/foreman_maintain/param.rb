module ForemanMaintain
  class Param
    attr_reader :name, :description, :options

    def initialize(name, description, options, &block)
      options.validate_options!(:description, :required, :flag, :array)
      @name = name
      @description = description || options[:description] || ''
      @options = options
      @required = @options.fetch(:required, false)
      @flag = @options.fetch(:flag, false)
      @block = block
      @array = @options.fetch(:array, false)
    end

    def flag?
      @flag
    end

    def required?
      @required
    end

    def array?
      @array
    end

    # rubocop:disable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
    def process(value)
      value = process_array(value) if array?
      value = @block.call(value) if @block
      if value.nil? && required?
        raise ArgumentError, "Param #{name} is required but no value given"
      elsif flag?
        value = value ? true : false
      end
      value
    end

    def process_array(value)
      if value.is_a?(Array)
        value
      else
        value.to_s.split(',').map(&:strip)
      end
    end
  end
end
