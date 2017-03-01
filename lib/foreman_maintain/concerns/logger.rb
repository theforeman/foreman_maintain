module ForemanMaintain
  module Concerns
    module Logger
      def logger
        @logger ||= ForemanMaintain.logger
      end
    end
  end
end
