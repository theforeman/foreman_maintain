require 'singleton'

module ForemanMaintain
  class ObjectCache
    include Singleton

    attr_reader :cache

    def initialize
      @cache = {}
    end

    def fetch(key)
      hit(key) || miss(key)
    end

    private

    def add(key, klass)
      return if key.nil? || klass.nil?
      cache[key.to_sym] = klass
    end

    def hit(key)
      cache.fetch(key, nil)
    end

    def miss(key)
      klass = ForemanMaintain.detector.available_checks(:label => key).first
      add(key, klass)
      hit(key)
    end
  end
end
