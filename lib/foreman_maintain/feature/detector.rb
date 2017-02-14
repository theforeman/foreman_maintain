module ForemanMaintain
  class Feature
    class Detector
      include Concerns::Logger

      # Returns instance of feature detected on system by label
      def feature(label)
        detect_features unless @available_features
        @features_by_label[label]
      end

      def available_features(force = false)
        return @available_features if !force && @available_features
        @available_features = detect_features
      end

      def detect_features
        @features_by_label = {}
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
          feature_label = feature.class.metadata[:label]
          next unless feature_label
          if @features_by_label[feature_label]
            raise "Double detection of feature with the same label #{feature_label}"
          end
          @features_by_label[feature_label] = feature
        end
      end
    end
  end
end
