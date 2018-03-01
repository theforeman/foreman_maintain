module ForemanMaintain
  class Detector
    include Concerns::Logger

    def initialize
      refresh
    end

    # Returns instance of feature detected on system by label
    def feature(label)
      detect_feature(label)
    end

    def filter(collection, conditions)
      if conditions
        collection = collection.find_all { |object| match_object?(object, conditions) }
      end
      sort(collection)
    end

    def refresh
      @features_by_label = {}
      @available_features = []
      @all_features_scanned = false
      @available_checks = nil
      @available_scenarios = nil
      @scenarios ||= Scenario.all_sub_classes.select(&:autodetect?)
    end

    def available_features(filter_conditions = nil)
      ensure_features_detected
      filter(@available_features, filter_conditions)
    end

    def available_checks(filter_conditions = nil)
      unless @available_checks
        ensure_features_detected
        @available_checks = find_present_classes(Check)
      end
      filter(@available_checks, filter_conditions)
    end

    def available_procedures(filter_conditions = nil)
      unless @available_procedures
        ensure_features_detected
        @available_procedures = find_present_classes(Procedure)
      end
      filter(@available_procedures, filter_conditions)
    end

    def available_reports(filter_conditions = nil)
      unless @available_reports
        ensure_features_detected
        @available_reports = find_present_classes(Report)
      end
      filter(@available_reports, filter_conditions)
    end

    def find_present_classes(object_base_class)
      object_base_class.all_sub_classes.reduce([]) do |array, object_class|
        array << object_class if object_class.present?
        array
      end
    end

    def available_scenarios(filter_conditions = nil)
      unless @available_scenarios
        ensure_features_detected
        @available_scenarios = @scenarios.select(&:present?).map(&:new)
      end
      filter(@available_scenarios, filter_conditions)
    end

    def ensure_features_detected
      return if @all_features_scanned
      @available_features = []
      @features_by_label = {}
      autodetect_features.each_key do |label|
        detect_feature(label)
      end
      @all_features_scanned = true
    end

    def all_scenarios(filter_conditions = nil)
      filter(@scenarios.map(&:new), filter_conditions)
    end

    private

    def sort(collection)
      collection.sort_by { |item| item.label.to_s }
    end

    def match_object?(object, conditions)
      conditions = normalize_filter_conditions(conditions)
      return false if conditions[:label] && object.label != conditions[:label]
      return false if conditions[:class] && object != conditions[:class]
      conditions[:tags].all? { |tag| object.metadata[:tags].include?(tag) }
    end

    def normalize_filter_conditions(conditions)
      ret = conditions.is_a?(Hash) ? conditions.dup : {}
      ret[:tags] = case conditions
                   when Symbol
                     [conditions]
                   when Array
                     conditions
                   when Hash
                     ret[:tags]
                   end
      ret[:tags] = Array(ret.fetch(:tags, []))
      ret
    end

    # rubocop:disable Metrics/AbcSize
    def detect_feature(label)
      return @features_by_label[label] if @features_by_label.key?(label)
      return unless autodetect_features.key?(label)
      present_feature_class = autodetect_features[label].find(&:present?)
      return unless present_feature_class
      present_feature = present_feature_class.new
      @available_features << present_feature
      # we don't allow duplicities of features that are autodetected
      add_feature_by_label(label, present_feature, false)
      additional_features = present_feature.additional_features
      @available_features.concat(additional_features)
      additional_features.each do |feature|
        # we allow duplicities if the feature is added via additional_features
        add_feature_by_label(feature.label, feature, true)
      end
      present_feature
    end
    # rubocop:enable Metrics/AbcSize

    def autodetect_features
      @autodetect_features ||= Feature.sub_classes.reduce({}) do |hash, feature_class|
        hash.update(feature_class.metadata[:label] =>
                      feature_class.all_sub_classes.select(&:autodetect?).reverse)
      end
    end

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
