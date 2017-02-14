module ForemanMaintain
  class Filter
    include Concerns::Logger

    attr_reader :collection
    attr_accessor :tags

    def initialize(collection, conditions = {})
      @collection = collection
      @tags = case conditions
              when Symbol
                [conditions]
              when Array
                conditions
              else
                Array(conditions.fetch(:tags, []))
              end
    end

    def run
      @collection.find_all do |sub_class|
        check_tags(sub_class)
      end
    end

    private

    def check_tags(sub_class)
      @tags.all? { |tag| sub_class.metadata[:tags].include?(tag) }
    end
  end
end
