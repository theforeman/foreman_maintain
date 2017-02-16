module ForemanMaintain
  class Executable
    attr_accessor :associated_feature

    def initialize(associated_feature)
      @associated_feature = associated_feature
    end

    # public method to be overriden
    def run
      raise NotImplementedError
    end

    # override to offer steps to be executed after this one
    def next_steps; end

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
  end
end
