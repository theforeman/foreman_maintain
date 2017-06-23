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
      @labels = extract_labels
      generate_label_graph
      convert_label_graph_to_object_graph
    end

    def add_to_graph(key, dependencies = [])
      return unless key

      dependencies = dependencies.map do |dep|
        next unless labels.include?(dep)
        dep
      end.compact

      graph[key] = dependencies
    end

    def tsort_each_node(&block)
      graph.each_key(&block)
    end

    def tsort_each_child(node, &block)
      graph.fetch(node).each(&block)
    end

    private

    def cache
      @cache ||= ObjectCache.new
    end

    def convert_label_graph_to_object_graph
      graph.keys.each do |key|
        graph[cache.fetch(key)] = graph[key].map { |dep| cache.fetch(dep) }
        graph.delete(key)
      end

      graph
    end

    def extract_labels
      collection.map(&:label)
    end

    def find_class(dep)
      case dep
      when Class
        dep
      when String
        if dep.include?('::')
          dep.split('::').reduce(Object) { |o, e| o.const_get(e) }
        else
          cache.fetch(dep)
        end
      else
        cache.fetch(dep)
      end
    end

    def generate_label_graph
      collection.each do |object|
        klass = object.class
        key = object.label

        add_to_graph(klass.before.first, [key])
        add_to_graph(key, klass.after)
        map_label_to_object(object)
      end
    end

    def map_label_to_object(object)
      cache.fetch(object.label, object)
    end
  end
end
