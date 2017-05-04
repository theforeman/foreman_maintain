module ForemanMaintain
  class Executable
    extend Forwardable
    attr_reader :options
    def_delegators :execution, :success?, :fail?, :output
    def_delegators :execution, :puts, :print, :with_spinner, :ask

    attr_accessor :associated_feature

    def initialize(options = {})
      @options = options.inject({}) { |h, (k, v)| h.update(k.to_s => v) }
      @param_values = {}
      setup_params
      after_initialize
    end

    # To be able to call uniq on a set of steps to deduplicate the same steps
    # inside the scenario
    def eql?(other)
      self.class.eql?(other.class) && options.eql?(other.options)
    end

    def hash
      [self.class, options].hash
    end

    # public method to be overriden to perform after-initialization steps
    def after_initialize; end

    # processes the params from provided options
    def setup_params
      @options.validate_options!(params.values.map(&:name).map(&:to_s))
      params.values.each do |param|
        set_param_variable(param.name, param.process(@options[param.name.to_s]))
      end
    end

    def set_param_variable(param_name, value)
      @param_values[param_name] = value
      if instance_variable_defined?("@#{param_name}")
        raise "Instance variable @#{param_name} already set"
      end
      instance_variable_set("@#{param_name}", value)
    end

    def associated_feature
      return @associated_feature if defined? @associated_feature
      if metadata[:for_feature]
        @associated_feature = feature(metadata[:for_feature])
      end
    end

    # next steps to be offered to the user after the step is run
    # It can be added for example from the assert method
    def next_steps
      @next_steps ||= []
    end

    # public method to be overriden
    def run
      raise NotImplementedError
    end

    def execution
      if @_execution
        @_execution
      else
        raise 'Trying to get execution information before the run started happened'
      end
    end

    # public method to be overriden: it can perform additional checks
    # to say, if the step is actually necessary to run. For example an `InstallPackage`
    # procedure would not be necessary when the package is already installed.
    def necessary?
      true
    end

    def fail!(message)
      execution.status = :fail
      execution.output << message
    end

    def warn!(message)
      execution.status = :warning
      execution.output << message
    end

    # update reporter about the current message
    def say(message)
      execution.update(message)
    end

    # internal method called by executor
    def __run__(execution)
      setup_execution_state(execution)
      run
    end

    # method defined both on object and class to ensure we work always with object
    # even when the definitions provide us only class
    def ensure_instance
      self
    end

    # clean the execution-specific state to prepare for the next execution
    # attempts
    def setup_execution_state(execution)
      @_execution = execution
      @next_steps = []
    end

    class << self
      def ensure_instance
        new
      end
    end
  end
end
