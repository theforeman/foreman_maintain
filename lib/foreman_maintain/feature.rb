module ForemanMaintain
  class Feature
    include Logger
    include SystemHelpers

    class << self
      include SystemHelpers
    end

    class Detector
      include Logger

      def initialize
        @features_registry = {}
      end

      def run
        Feature.sub_features.map do |feature_class|
          feature = detect_on_system(feature_class)
          if feature
            logger.debug("detected #{feature} of #{feature_class}")
          end
          feature
        end.flatten.compact
      end

      def detect_on_system(feature)
        # first check if there are not available some more specialized versions
        feature.sub_features.each do |sub_feature|
          detected_sub_feature = detect_on_system(sub_feature)
          return detected_sub_feature if detected_sub_feature
        end

        # we have not detected the feature defined in children:
        # let's try this class itself
        feature.metadata[:detection_block].call
      end
    end

    def self.inherited(klass)
      sub_features << klass
    end

    def self.sub_features
      @sub_features ||= []
    end

    def self.metadata
      return @metadata if @metadata
      @metadata = {}
      if superclass.respond_to?(:metadata)
        @metadata[:feature_name] = superclass.metadata[:feature_name]
      end
      @metadata
    end

    def self.inspect
      "Feature Class #{metadata[:feature_name]}<#{name}>"
    end

    def inspect
      "#{self.class.metadata[:feature_name]}<#{self.class.name}>"
    end

    # DSL
    def self.feature_name(name)
      metadata[:feature_name] = name
    end

    def self.detect(&block)
      metadata[:detection_block] = block
    end
  end
end
