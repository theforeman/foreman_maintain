module ForemanMaintain
  module Concerns
    module Hammer
      def self.included(base)
        base.metadata do
          preparation_steps { Procedures::HammerSetup.new }
        end
      end
    end
  end
end
