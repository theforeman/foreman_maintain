require 'test_helper'

module ForemanMaintain
  describe YamlStorage do
    let :storage_sample do
      YamlStorage.new(:post_upgrade, :key => 'test data')
    end

    def nested_hash_value(obj, key)
      if obj.respond_to?(:key?) && obj.key?(key)
        obj[key]
      elsif obj.respond_to?(:each)
        matching_obj = nil
        obj.find { |*o| matching_obj = nested_hash_value(o.last, key) }
        matching_obj
      end
    end

    before do
      file_path = YamlStorage.storage_file_path
      File.delete(file_path) if File.exist?(file_path)
    end

    it 'Empty hash for key which is not present' do
      details = ForemanMaintain.storage(:test_upgrade)
      assert_equal(:test_upgrade, details.sub_key, 'expected sub_key should be match')
      assert_equal({}, details.data, 'expected empty hash')
    end

    it 'saves data to file using save method' do
      old_storage = ForemanMaintain.storage(:upgrade)
      sp_data = { :enabled => [], :disabled => [1] }
      old_storage[:sync_plans] = sp_data
      old_storage.save
      assert_equal(YamlStorage, old_storage.class, 'expected YamlStorage object')
      new_storage = ForemanMaintain.storage(:upgrade)
      sp_new_data = nested_hash_value(new_storage.data, :sync_plans)
      assert_equal([1], sp_new_data[:disabled], 'expected values should be match')
    end

    it 'returns YamlStorage object using load method' do
      YamlStorage.instance_variable_set('@storage_register',
                                        :post_upgrade => { :key => 'test data' })
      yml_storage_obj = YamlStorage.load(:post_upgrade)
      assert_equal storage_sample.class, yml_storage_obj.class
      storage_sample.sub_key.must_equal yml_storage_obj.sub_key
      storage_sample.data.must_equal yml_storage_obj.data
    end
  end
end
