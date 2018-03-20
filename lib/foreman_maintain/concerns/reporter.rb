module ForemanMaintain
  module Concerns
    module Reporter
      extend Forwardable
      def_delegators :reporter, :with_spinner, :puts, :print, :ask, :assumeyes?

      def reporter
        ForemanMaintain.reporter
      end
    end
  end
end
