module ForemanMaintain
  class Feature
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

    class Detector
      include Concerns::Logger

      # Returns instance of feature detected on system by name
      def feature(name)
        detect_features unless @available_features
        @features_by_name[name]
      end

      def available_features(force = false)
        return @available_features if !force && @available_features
        @available_features = detect_features
      end

      def detect_features
        @features_by_name = {}
        @available_features = Feature.sub_classes.map do |feature_class|
          features = detect_on_system(feature_class)
          unless features.empty?
            logger.debug("detected #{features} of #{feature_class}")
          end
          features
        end.flatten
        initialize_features_by_name
        @available_features
      end

      private

      def detect_on_system(feature)
        # first check if there are not available some more specialized versions
        feature.sub_classes.each do |sub_feature|
          detected_sub_feature = detect_on_system(sub_feature)
          return detected_sub_feature unless detected_sub_feature.empty?
        end

        # we have not detected the feature defined in children:
        # let's try this class itself
        Array(feature.metadata[:detection_block].call)
      end

      def initialize_features_by_name
        @available_features.each do |feature|
          feature_name = feature.class.metadata[:feature_name]
          next unless feature_name
          if @features_by_name[feature_name]
            raise "Double detection of feature with the same name #{feature_name}"
          end
          @features_by_name[feature_name] = feature
        end
      end
    end

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
