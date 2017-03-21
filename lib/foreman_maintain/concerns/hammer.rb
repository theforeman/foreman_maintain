module ForemanMaintain
  module Concerns
    module Hammer
      # Run a hammer command, examples:
      # hammer('host list')
      def hammer(args)
        Utils::Hammer.instance.run_command(args)
      end

      # TODO: method for specifying that the check that includes this method
      # requires hammer to be setup
    end
  end
end
