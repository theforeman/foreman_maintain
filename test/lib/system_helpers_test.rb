require 'test_helper'

class MicroSystem
  include ForemanMaintain::Concerns::SystemHelpers
end

module ForemanMaintain
  describe Concerns::SystemHelpers do
    let(:system) { MicroSystem.new }

    describe '.find_package' do
      it 'returns nil if package does not exist' do
        PackageManagerTestHelper.assume_package_exist([])
        assert_nil system.find_package('unknown')
      end
    end

    describe '.check_min_version version ' do
      it 'returns false if current package version is less than the supplied version' do
        MicroSystem.any_instance.stubs(:package_version).returns(
          MicroSystem::Version.new('3.18.3')
        )
        refute system.check_min_version('katello', '4.0.0')
      end

      it 'returns true if current package version is equal to the supplied version' do
        MicroSystem.any_instance.stubs(:package_version).returns(
          MicroSystem::Version.new('4.0.0')
        )
        assert system.check_min_version('katello', '4.0')
      end

      it 'returns true if current package version is greater than supplied version' do
        MicroSystem.any_instance.stubs(:package_version).returns(
          MicroSystem::Version.new('4.0.1')
        )
        assert system.check_min_version('katello', '4.0')
      end
    end

    describe '.check_max_version version ' do
      it 'returns true if package version is greater than current package version' do
        MicroSystem.any_instance.stubs(:package_version).returns(
          MicroSystem::Version.new('3.18.1')
        )
        assert system.check_max_version('katello', '3.18.2')
      end

      it 'returns true if package version is equal to current package version with no minor' do
        MicroSystem.any_instance.stubs(:package_version).returns(
          MicroSystem::Version.new('3.18.1')
        )
        assert system.check_max_version('katello', '3.18.1')
      end

      it 'returns false if package version is greater than current package version with no minor' do
        MicroSystem.any_instance.stubs(:package_version).returns(
          MicroSystem::Version.new('3.18.1')
        )
        refute system.check_max_version('katello', '3.18')
      end
    end
  end
end
