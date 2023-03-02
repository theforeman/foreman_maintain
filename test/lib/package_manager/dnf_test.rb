require 'test_helper'
require 'tempfile'
require 'foreman_maintain/package_manager'

module ForemanMaintain
  describe PackageManager::Dnf do
    def expect_execute_with_status(command, response: [0, ''])
      ForemanMaintain::Utils::SystemHelpers.
        expects(:execute_with_status).
        with(command, :interactive => false).
        returns(response)
    end

    def expect_execute!(command, response: true)
      ForemanMaintain::Utils::SystemHelpers.
        expects(:execute!).
        with(command, :interactive => false).
        returns(response)
    end

    subject { PackageManager::Dnf.new }
    let(:enabled_module) { 'Stream           : el8 [e] [a]' }
    let(:disabled_module) { 'Stream           : el8' }
    let(:non_existent_module) { 'Unable to resolve argument satellit' }

    describe 'module_enabled?' do
      it 'checks if a module is enabled' do
        expect_execute_with_status(
          'dnf -y module info test-module:el8',
          :response => [0, enabled_module]
        )
        assert subject.module_enabled?('test-module:el8')
      end

      it 'returns false if module does not exist' do
        expect_execute_with_status(
          'dnf -y module info test-module:el8',
          :response => [1, non_existent_module]
        )
        assert !subject.module_enabled?('test-module:el8')
      end

      it 'returns false if module exists but is not enabled' do
        expect_execute_with_status(
          'dnf -y module info test-module:el8',
          :response => [0, disabled_module]
        )
        assert !subject.module_enabled?('test-module:el8')
      end
    end

    describe 'enable_module' do
      it 'enables a module by name' do
        expect_execute!('dnf -y module enable test-module:el8')
        assert subject.enable_module('test-module:el8')
      end
    end

    describe 'module_exists?' do
      it 'check if a module exists' do
        expect_execute_with_status('dnf -y module info test-module:el8')
        assert subject.module_exists?('test-module:el8')
      end
    end
  end
end
