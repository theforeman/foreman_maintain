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
        assert system.current_minor_version == '6.10'
      end
    end

    describe '.ansible_repo' do
      it 'returns correct ansible 2.9 repo for 6.9 on el7' do
        system.stubs(:el_major_version).returns(7)
        assert_equal 'rhel-7-server-ansible-2.9-rpms',
                     system.send(:ansible_repo, system.version('6.9'))
      end

      it 'returns no ansible 2.9 repo for 6.11 on el8' do
        system.stubs(:el_major_version).returns(8)
        assert_nil system.send(:ansible_repo, system.version('6.11'))
      end
    end

    describe '.product_specific_repos' do
      it 'returns correct repos for sat 6.10 on el7' do
        system.stubs(:el_major_version).returns(7)
        expected_repos = ['rhel-7-server-satellite-6.10-rpms',
                          'rhel-7-server-satellite-maintenance-6-rpms']
        assert_equal expected_repos,
                     system.send(:product_specific_repos, '6.10')
      end

      it 'returns correct repos for sat 6.11 on el8' do
        system.stubs(:el_major_version).returns(8)
        expected_repos = ['satellite-6.11-for-rhel-8-x86_64-rpms',
                          'satellite-maintenance-6.11-for-rhel-8-x86_64-rpms']
        assert_equal expected_repos,
                     system.send(:product_specific_repos, '6.11')
      end

      it 'returns correct beta repos for sat 6.10 on el7' do
        system.stubs(:use_beta_repos?).returns(true)
        system.stubs(:el_major_version).returns(7)
        expected_repos = ['rhel-server-7-satellite-6-beta-rpms',
                          'rhel-7-server-satellite-maintenance-6-beta-rpms']
        assert_equal expected_repos,
                     system.send(:product_specific_repos, '6.10')
      end

      it 'returns correct beta repos for sat 6.11 on el8' do
        system.stubs(:use_beta_repos?).returns(true)
        system.stubs(:el_major_version).returns(8)
        expected_repos = ['satellite-6-beta-for-rhel-8-x86_64-rpms',
                          'satellite-maintenance-6-beta-for-rhel-8-x86_64-rpms']
        assert_equal expected_repos,
                     system.send(:product_specific_repos, '6.11')
      end

      it 'returns correct repos for capsule 6.10 on el7' do
        capsule.stubs(:el_major_version).returns(7)
        expected_repos = ['rhel-7-server-satellite-capsule-6.10-rpms',
                          'rhel-7-server-satellite-maintenance-6-rpms']
        assert_equal expected_repos,
                     capsule.send(:product_specific_repos, '6.10')
      end

      it 'returns correct repos for capsule 6.11 on el8' do
        capsule.stubs(:el_major_version).returns(8)
        expected_repos = ['satellite-capsule-6.11-for-rhel-8-x86_64-rpms',
                          'satellite-maintenance-6.11-for-rhel-8-x86_64-rpms']
        assert_equal expected_repos,
                     capsule.send(:product_specific_repos, '6.11')
      end

      it 'returns correct beta repos for capsule 6.10 on el7' do
        capsule.stubs(:use_beta_repos?).returns(true)
        capsule.stubs(:el_major_version).returns(7)
        expected_repos = ['rhel-server-7-satellite-capsule-6-beta-rpms',
                          'rhel-7-server-satellite-maintenance-6-beta-rpms']
        assert_equal expected_repos,
                     capsule.send(:product_specific_repos, '6.10')
      end

      it 'returns correct beta repos for capsule 6.11 on el8' do
        capsule.stubs(:use_beta_repos?).returns(true)
        capsule.stubs(:el_major_version).returns(8)
        expected_repos = ['satellite-capsule-6-beta-for-rhel-8-x86_64-rpms',
                          'satellite-maintenance-6-beta-for-rhel-8-x86_64-rpms']
        assert_equal expected_repos,
                     capsule.send(:product_specific_repos, '6.11')
      end
    end

    describe '.common_repos' do
      it 'returns correct maintenance repo for 6.10 on el7' do
        system.stubs(:el_major_version).returns(7)
        assert_equal ['rhel-7-server-satellite-maintenance-6-rpms'],
                     system.send(:common_repos, '6.10')
      end

      it 'returns correct maintenance repo for 6.11 on el7' do
        system.stubs(:el_major_version).returns(7)
        assert_equal ['rhel-7-server-satellite-maintenance-6.11-rpms'],
                     system.send(:common_repos, '6.11')
      end

      it 'returns correct maintenance repo for 6.11 on el8' do
        system.stubs(:el_major_version).returns(8)
        assert_equal ['satellite-maintenance-6.11-for-rhel-8-x86_64-rpms'],
                     system.send(:common_repos, '6.11')
      end

      it 'returns correct beta maintenance repo for 6.10 on el7' do
        system.stubs(:use_beta_repos?).returns(true)
        system.stubs(:el_major_version).returns(7)
        assert_equal ['rhel-7-server-satellite-maintenance-6-beta-rpms'],
                     system.send(:common_repos, '6.10')
      end

      it 'returns correct beta maintenance repo for 6.11 on el7' do
        system.stubs(:use_beta_repos?).returns(true)
        system.stubs(:el_major_version).returns(7)
        assert_equal ['rhel-7-server-satellite-maintenance-6-beta-rpms'],
                     system.send(:common_repos, '6.11')
      end

      it 'returns correct beta maintenance repo for 6.11 on el8' do
        system.stubs(:use_beta_repos?).returns(true)
        system.stubs(:el_major_version).returns(8)
        assert_equal ['satellite-maintenance-6-beta-for-rhel-8-x86_64-rpms'],
                     system.send(:common_repos, '6.11')
      end
    end

    describe '.main_rh_repos' do
      it 'returns correct repos on el7' do
        expected_repos = ['rhel-7-server-rpms', 'rhel-server-rhscl-7-rpms']
        system.stubs(:el_major_version).returns(7)
        assert_equal expected_repos,
                     system.send(:main_rh_repos)
      end

      it 'returns correct repos on el8' do
        expected_repos = ['rhel-8-for-x86_64-baseos-rpms', 'rhel-8-for-x86_64-appstream-rpms']
        system.stubs(:el_major_version).returns(8)
        assert_equal expected_repos,
                     system.send(:main_rh_repos)
      end
    end
  end
end
