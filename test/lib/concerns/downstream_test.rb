require 'test_helper'

class FakeSatelliteFeature
  include ForemanMaintain::Concerns::SystemHelpers
  include ForemanMaintain::Concerns::Downstream
  include ForemanMaintain::Concerns::Versions

  def package_name
    'satellite'
  end

  def current_version
    @current_version ||= version('6.10.1')
  end
end

class FakeCapsuleFeature < FakeSatelliteFeature
  def package_name
    'satellite-capsule'
  end
end

module ForemanMaintain
  describe Concerns::Downstream do
    let(:system) { FakeSatelliteFeature.new }
    let(:capsule) { FakeCapsuleFeature.new }

    describe '.current_minor_version' do
      it 'returns correct minor version' do
        assert_equal system.current_minor_version, '6.10'
      end
    end

    describe '.product_specific_repos' do
      it 'returns correct repos for sat 6.11 on el8' do
        system.stubs(:el_major_version).returns(8)
        expected_repos = ['satellite-6.11-for-rhel-8-x86_64-rpms',
                          'satellite-maintenance-6.11-for-rhel-8-x86_64-rpms']
        assert_equal expected_repos,
          system.send(:product_specific_repos, '6.11')
      end

      it 'returns correct repos for capsule 6.11 on el8' do
        capsule.stubs(:el_major_version).returns(8)
        expected_repos = ['satellite-capsule-6.11-for-rhel-8-x86_64-rpms',
                          'satellite-maintenance-6.11-for-rhel-8-x86_64-rpms']
        assert_equal expected_repos,
          capsule.send(:product_specific_repos, '6.11')
      end
    end

    describe '.common_repos' do
      it 'returns correct maintenance repo for 6.11 on el8' do
        system.stubs(:el_major_version).returns(8)
        assert_equal ['satellite-maintenance-6.11-for-rhel-8-x86_64-rpms'],
          system.send(:common_repos, '6.11')
      end
    end

    describe '.main_rh_repos' do
      it 'returns correct repos on el8' do
        expected_repos = ['rhel-8-for-x86_64-baseos-rpms', 'rhel-8-for-x86_64-appstream-rpms']
        system.stubs(:el_major_version).returns(8)
        assert_equal expected_repos,
          system.send(:main_rh_repos)
      end
    end
  end
end
