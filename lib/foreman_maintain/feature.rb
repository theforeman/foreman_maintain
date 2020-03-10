module ForemanMaintain
  class Feature
    include Concerns::Logger
    include Concerns::Reporter
    include Concerns::SystemHelpers
    include Concerns::SystemService
    include Concerns::Metadata
    include Concerns::Finders
    include ForemanMaintain::Concerns::Hammer

    def self.inspect
      "Feature Class #{metadata[:label]}<#{name}>"
    end

    def inspect
      "#{self.class.metadata[:label]}<#{self.class.name}>"
    end

    # Override method with list of applicable services for feature.
    # Services have a number for priority in order to ensure
    # they are started and stopped in the correct order.
    # example:
    # [ system_service('foo', 10), system_service('bar', 20) ]
    def services
      []
    end

    # Override to generate additional feature instances that can't be
    # autodetected directly
    def additional_features
      []
    end

    # list of config files the feature uses
    def config_files
      []
    end

    # list of config files to be excluded from the list of config files.
    # Can be used to exclude subdir from whole config directory
    def config_files_to_exclude
      []
    end

    def config_files_exclude_for_online
      []
    end
  end
end
