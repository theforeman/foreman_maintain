module ForemanMaintain
  class Executable
    attr_accessor :associated_feature

    def associated_feature
      return @associated_feature if defined? @associated_feature
      if metadata[:for_feature]
        @associated_feature = feature(metadata[:for_feature])
      end
    end

    # public method to be overriden
    def run
      raise NotImplementedError
    end

    # next steps to be offered to the user after the step is run
    # It can be added for example from the assert method
    def next_steps
      @next_steps ||= []
    end

    def execution
      if @_execution
        @_execution
      else
        raise 'Trying to get execution information before the run started happened'
      end
    end

    def success?
      execution.success?
    end

    def fail?
      execution.fail?
    end

    # update reporter about the current message
    def say(message)
      @_execution.update(message)
    end

    # internal method called by executor
    def __run__(execution)
      @_execution = execution
      run
    end

    # method defined both on object and class to ensure we work always with object
    # even when the definitions provide us only class
    def ensure_instance
      self
    end

    class << self
      def ensure_instance
        new
      end
    end
  end
end
