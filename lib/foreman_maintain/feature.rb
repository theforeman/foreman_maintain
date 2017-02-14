module ForemanMaintain
  class Feature
    require 'foreman_maintain/feature/detector'

    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata

    module DSL
      def detect(&block)
        metadata[:detection_block] = block
      end
    end
    extend DSL

    def self.inspect
      "Feature Class #{metadata[:label]}<#{name}>"
    end

    def inspect
      "#{self.class.metadata[:label]}<#{self.class.name}>"
    end
  end
end
