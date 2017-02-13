module ForemanMaintain
  class Filter
    include Concerns::Logger

    attr_reader :base_class
    attr_accessor :tags

    def initialize(base_class, conditions = {})
      @base_class = base_class
      @tags = case conditions
              when Symbol
                [conditions]
              when Array
                conditions
              else
                Array(conditions.fetch(:tags, []))
              end
      @detector = ForemanMaintain.features_detector
    end

    def run
      @base_class.all_sub_classes.find_all do |sub_class|
        raise "#{sub_class} doesn't have metadata" unless sub_class.respond_to?(:metadata)
        check_required_features(sub_class) && check_tags(sub_class)
      end
    end

    private

    def check_required_features(sub_class)
      sub_class.metadata[:required_features].all? do |required_feature|
        @detector.feature(required_feature)
      end
    end

    def check_tags(sub_class)
      @tags.all? { |tag| sub_class.metadata[:tags].include?(tag) }
    end
  end
end
