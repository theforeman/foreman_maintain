require 'singleton'

module ForemanMaintain
  class ObjectCache
    include Singleton

    attr_reader :cache

    def initialize
      @cache = {}
    end

    def fetch(key, object = nil)
      hit(key) || miss(key, object)
    end

    private

    def add(key, object)
      return if key.nil? || object.nil?
      cache[key.to_sym] = object
    end

    def hit(key)
      cache.fetch(key, nil)
    end

    def miss(key, object)
      object ||= ForemanMaintain.detector.available_checks(:label => key).first
      add(key, object)
      hit(key)
    end
  end
end
