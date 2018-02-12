module ForemanMaintain
  class Feature
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders
    include ForemanMaintain::Concerns::Hammer

    def self.inspect
      "Feature Class #{metadata[:label]}<#{name}>"
    end

    def inspect
      "#{self.class.metadata[:label]}<#{self.class.name}>"
    end

    # Override method with hash of applicable services for feature.
    # Services have a number for priority in order to ensure
    # they are started and stopped in the correct order.
    # example:
    # { :foo_service => 10, :bar_service => 20 }
    def services
      {}
    end

    # Override to generate additional feature instances that can't be
    # autodetected directly
    def additional_features
      []
    end
  end
end
