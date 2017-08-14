require 'tsort'

module ForemanMaintain
  class DependencyGraph
    include TSort

    attr_reader :graph, :collection, :labels

    def self.sort(collection)
      new(collection).tsort.map(&:ensure_instance)
    end

    def initialize(collection)
      @graph = Hash.new([])
      @collection = collection
      @steps_by_labels = @collection.group_by(&:label)
      generate_label_graph
    end

    def add_to_graph(key, dependencies = [])
      return unless key

      graph[key] = dependencies
    end

    def tsort_each_node(&block)
      @collection.each(&block)
    end

    def tsort_each_child(node, &block)
      graph.fetch(node).each(&block)
    end

    private

    def generate_label_graph
      collection.each do |object|
        klass = object.is_a?(Class) ? object : object.class
        klass.before.each do |label|
          add_to_graph(labels_to_objects(label).first, [object])
        end
        add_to_graph(object, labels_to_objects(klass.after))
      end
    end

    def labels_to_objects(labels)
      labels = Array(labels)
      labels.map { |label| @steps_by_labels[label] }.compact.flatten
    end
  end
end
