module ForemanMaintain
  class Feature
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders

    def self.inspect
      "Feature Class #{metadata[:label]}<#{name}>"
    end

    def inspect
      "#{self.class.metadata[:label]}<#{self.class.name}>"
    end

    # Override to generate additional feature instances that can't be
    # autodetected directly
    def additional_features
      []
    end
  end
end
