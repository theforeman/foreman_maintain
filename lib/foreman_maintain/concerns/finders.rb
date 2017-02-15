module ForemanMaintain
  module Concerns
    module Finders
      def detector
        @detector ||= ForemanMaintain.detector
      end

      def feature(label)
        detector.feature(label)
      end

      def find_checks(conditions)
        detector.available_checks(conditions)
      end
    end
  end
end
