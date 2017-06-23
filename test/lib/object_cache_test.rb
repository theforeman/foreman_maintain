require 'test_helper'

module ForemanMaintain
  describe ObjectCache do
    include ResetTestState

    let :cache do
      ObjectCache.new
    end

    it 'has a hit on a existing key' do
      cache.stubs(:cache).returns(:key_found => 'A Class name')
      refute_nil cache.fetch(:key_found)
    end

    it 'misses for a non-existing key' do
      mock_obj = mock
      Detector.any_instance.stubs(:available_checks).returns([mock_obj])
      refute_nil cache.fetch(:key_not_found, mock_obj)
    end

    it 'does not cache nil values' do
      Detector.any_instance.stubs(:available_checks).returns([])
      cache.fetch(:some_key)
      assert_nil cache.cache[:some_key]
    end
  end
end
