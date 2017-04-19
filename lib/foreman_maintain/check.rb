module ForemanMaintain
  class Check < Executable
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders

    attr_accessor :associated_feature

    # run condition and mark the check as failed when not passing
    #
    # ==== Options
    #
    # * +:next_steps* - one or more procedures that can be followed to address
    #                   the failure, will be offered to the user when running
    #                   in interactive mode
    def assert(condition, error_message, options = {})
      options = options.validate_options!(:next_steps)
      unless condition
        next_steps = Array(options.fetch(:next_steps, []))
        self.next_steps.concat(next_steps)
        raise Error::Fail, error_message
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
      fail!(e.message)
    rescue Error::Warn => e
      warn!(e.message)
    end
  end
end
