require 'tsort'

module ForemanMaintain
  class DependencyGraph
    include TSort

    attr_reader :graph, :collection

    def self.sort(collection)
      new(collection).tsort.map(&:ensure_instance)
    end

    def initialize(collection)
      @graph = Hash.new([])
      @collection = sanitize_collection(collection)
      generate_rule
    end

    def add(key, dependencies = [])
      key = cache.fetch(key) unless key.is_a?(Class)

      return unless key

      dependencies = dependencies.map do |dep|
        klass = find_class(dep)

        next unless collection.include?(klass)
        klass
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
      ForemanMaintain.cache
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

    def generate_rule
      collection.each do |klass|
        add(klass.before.first, [klass]) unless klass.before.empty?
        add(klass, klass.after)
      end
    end

    def sanitize_collection(collection)
      collection.map do |object|
        object.is_a?(Class) ? object : object.class
      end.compact
    end
  end
end
