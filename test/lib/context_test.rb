require 'test_helper'

module ForemanMaintain
  describe Context do
    let(:context) { ForemanMaintain::Context.new }

    it 'stores key-value' do
      context.set(:backup_dir, '/tmp')
      assert_equal '/tmp', context.get(:backup_dir)
    end

    it 'allows to fetch value with preset default' do
      assert_equal '/tmp/default', context.get(:backup_dir, '/tmp/default')
    end

    it 'returns the key-values as an hash' do
      context.set(:backup_dir, '/tmp')
      expected = { :backup_dir => '/tmp' }
      assert_equal expected, context.to_hash
    end

    describe 'mapping' do
      let(:context) { ForemanMaintain::Context.new(:backup_dir => '/tmp') }

      class FakeProcedure; end
      class FakeCheck; end

      it 'allows to set mapping for a key' do
        context.map(:backup_dir, ForemanMaintain::FakeProcedure => :backup_directory)
        expected_params = { :backup_directory => '/tmp' }
        assert_equal expected_params, context.params_for(ForemanMaintain::FakeProcedure)
      end

      it 'allows set key with mapping in one set' do
        context.set(:debug, true, ForemanMaintain::FakeProcedure => :debugger)
        expected_params = { :debugger => true }
        assert_equal expected_params, context.params_for(ForemanMaintain::FakeProcedure)
      end

      it 'allows to extend mapping' do
        context.map(:backup_dir, ForemanMaintain::FakeProcedure => :backup_directory)
        context.map(:backup_dir, ForemanMaintain::FakeCheck => :backup_directory)
        expected_params = { :backup_directory => '/tmp' }
        assert_equal expected_params, context.params_for(ForemanMaintain::FakeProcedure)
        assert_equal expected_params, context.params_for(ForemanMaintain::FakeCheck)
      end
    end
  end
end
