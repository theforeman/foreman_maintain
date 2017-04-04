module ForemanMaintain
  class Check < Executable
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders

    attr_accessor :associated_feature

    class Fail < StandardError
    end

    # run condition and mark the check as failed when not passing
    #
    # ==== Options
    #
    # * +:next_steps* - one or more procedures that can be followed to address
    #                   the failure, will be offered to the user when running
    #                   in interactive mode
    def assert(condition, error_message, options = {})
      unexpected_options = options.keys - [:next_steps]
      unless unexpected_options.empty?
        raise ArgumentError, "Unexpected options #{unexpected_options.inspect}"
      end
      unless condition
        next_steps = Array(options.fetch(:next_steps, []))
        self.next_steps.concat(next_steps)
        raise Fail, error_message
      end
    end

    # public method to be overriden
    def run
      raise NotImplementedError
    end

    # internal method called by executor
    def __run__(execution)
      super
    rescue Error::Fail => e
      execution.status = :fail
      execution.output << e.message
    end
  end
end
