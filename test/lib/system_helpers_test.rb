require 'test_helper'

class MicroSystem
  include ForemanMaintain::Concerns::SystemHelpers
end

module ForemanMaintain
  describe Concerns::SystemHelpers do
    let(:system) { MicroSystem.new }

    describe '.find_package' do
      it 'returns nil if package does not exist' do
        Features::PackageManager.any_instance.stubs(:find_installed_package).
          with('unknown').returns(nil)
        assert_nil system.find_package('unknown')
      end
    end
  end
end
