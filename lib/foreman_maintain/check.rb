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
    #
    # * +:warn* - issue warning instead of failure: this is less strict check,
    #      that could be considered as non-critical for continuing with the scenario
    def assert(condition, error_message, options = {})
      options = options.validate_options!(:next_steps, :warn)
      unless condition
        next_steps = Array(options.fetch(:next_steps, []))
        self.next_steps.concat(next_steps)
        if options[:warn]
          warn!(error_message)
        else
          fail!(error_message)
        end
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
      set_fail(e.message)
    rescue Error::Warn => e
      set_warn(e.message)
    end
  end
end
