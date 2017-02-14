module ForemanMaintain
  class Detector
    include Concerns::Logger

    def initialize
      @features_by_label = {}
      @available_features = []
      @all_features_scanned = false
    end

    # Returns instance of feature detected on system by label
    def feature(label)
      return @features_by_label[label] if @features_by_label.key?(label)
      detect_feature(label)
    end

    def available_features(force = false)
      ensure_features_detected(force)
      @available_features
    end

    def available_checks(force = false)
      return @available_checks if @available_checks
      ensure_features_detected(force)
      @available_checks = Check.all_sub_classes.reduce([]) do |array, check_class|
        feature_label = check_class.metadata[:for_feature]
        check = check_class.new(feature_label && feature(feature_label))
        array << check if check.present?
        array
      end
    end

    def available_scenarios(force = false)
      return @available_scenarios if @available_scenarios
      ensure_features_detected(force)
      @available_scenarios = Scenario.all_sub_classes.map(&:new).select(&:present?)
    end

    def ensure_features_detected(force)
      return if !force && @all_features_scanned
      @available_features = []
      @features_by_label = {}
      autodetect_features.keys.each do |label|
        detect_feature(label)
      end
      @all_features_scanned = true
    end

    private

    def detect_feature(label)
      return unless autodetect_features.key?(label)
      present_feature = autodetect_features[label].find(&:present?)
      return unless present_feature
      @available_features << present_feature
      # we don't allow duplicities of features that are autodetected
      add_feature_by_label(label, present_feature, false)
      additional_features = present_feature.additional_features
      @available_features.concat(additional_features)
      additional_features.each do |feature|
        # we allow duplicities if the feature is added via additional_features
        add_feature_by_label(feature.metadata[:label], feature, true)
      end
    end

    def autodetect_features
      @autodetect_features ||= Feature.sub_classes.reduce({}) do |hash, feature_class|
        hash.update(feature_class.metadata[:label] =>
                      feature_class.all_sub_classes.select(&:autodetect?).reverse.map(&:new))
      end
    end

    # rubocop:disable Metrics/MethodLength
    def add_feature_by_label(feature_label, feature, allow_duplicities)
      if @features_by_label.key?(feature_label)
        if allow_duplicities
          unless @features_by_label[feature_label].is_a? Array
            @features_by_label[feature_label] = Array(@features_by_label[feature_label])
          end
          @features_by_label[feature_label] << feature
        else
          raise "Double detection of feature with the same label #{feature_label}:" \
                  "#{feature.inspect} vs. #{@features_by_label[feature_label].inspect}"
        end
      else
        @features_by_label[feature_label] = feature
      end
    end
  end
end
