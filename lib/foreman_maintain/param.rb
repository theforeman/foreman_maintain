module ForemanMaintain
  class Param
    attr_reader :name, :description, :options

    def initialize(name, description, options, &block)
      options.validate_options!(:description, :required, :flag, :array, :allowed_values, :default)
      @name = name
      @description = description || options[:description] || ''
      @options = options
      @required = @options.fetch(:required, false)
      @flag = @options.fetch(:flag, false)
      @block = block
      @allowed_values = @options.fetch(:allowed_values, [])
      @array = @options.fetch(:array, false)
      @default = @options.fetch(:default, nil)
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

    def process(value)
      # default values imply we can not pass nil if there is non-nil default
      value = @default if value.nil?
      value = process_array(value) if array?
      value = @block.call(value) if @block
      if value.nil? && required?
        raise ArgumentError, "Param #{name} is required but no value given"
      elsif flag?
        value = value ? true : false
      end
      validate_with_allowed_values(value)
      value
    end

    def process_array(value)
      if value.is_a?(Array)
        value
      else
        value.to_s.split(',').map(&:strip)
      end
    end

    def validate_with_allowed_values(value)
      return if @allowed_values.empty?
      within_allowed = case value
                       when Array
                         (value - @allowed_values).empty?
                       when Symbol, String
                         @allowed_values.include?(value.to_s)
                       else
                         raise NotImplementedError
                       end
      return if within_allowed
      error_msg = "'#{value}' not allowed for #{name} param."
      raise ForemanMaintain::Error::UsageError,
            "#{error_msg} Possible values are #{@allowed_values.join(', ')}"
    end
  end
end
