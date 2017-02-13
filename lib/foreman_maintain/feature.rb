module ForemanMaintain
  class Feature
    require 'foreman_maintain/feature/detector'

    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata

    module DSL
      def feature_name(name)
        metadata[:feature_name] = name
      end

      def detect(&block)
        metadata[:detection_block] = block
      end
    end
    extend DSL

    def self.initialize_metadata
      super.tap do |metadata|
        if superclass.respond_to?(:metadata)
          metadata[:feature_name] = superclass.metadata[:feature_name]
        end
      end
    end

    def self.inspect
      "Feature Class #{metadata[:feature_name]}<#{name}>"
    end

    def inspect
      "#{self.class.metadata[:feature_name]}<#{self.class.name}>"
    end
  end
end
