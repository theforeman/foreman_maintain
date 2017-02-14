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
        Filter.new(detector.available_checks, conditions).run
      end
    end
  end
end
