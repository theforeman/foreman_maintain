require 'test_helper'
require_relative '../test_helper'
require_relative '../../../definitions/scenarios/self_upgrade'

describe ForemanMaintain::Scenarios::SelfUpgradeBase do
  include ::DefinitionsTestHelper

  before do
    File.stubs(:exist?).with('/etc/redhat-release').returns(true)
    mock_satellite_maintain_config
  end

  let(:scenario) do
    ForemanMaintain::Scenarios::SelfUpgradeBase.new
  end

  it 'computes the target version correctly for downstream' do
    assume_satellite_present
    ForemanMaintain.package_manager.
      stubs(:find_installed_package).
      with('satellite', '%{VERSION}').returns('6.16.0')

    assert_equal '6.17', scenario.upgrade_repo_version
  end

  it 'returns target version correctly for upstream' do
    assume_feature_present(:foreman_install)

    assert_equal '3.12', scenario.target_version
  end

  it 'allow upgrade when versions are off by 1' do
    assume_satellite_present
    scenario.stubs(:current_version).returns('6.15.8')

    assert scenario.self_upgrade_allowed?
  end

  it 'does not allow upgrade when versions are off by 2 or more' do
    assume_satellite_present
    scenario.stubs(:current_version).returns('6.14.4')

    refute scenario.self_upgrade_allowed?
  end
end

describe ForemanMaintain::Scenarios::SelfUpgrade do
  include ::DefinitionsTestHelper

  before do
    File.stubs(:exist?).with('/etc/redhat-release').returns(true)
    mock_satellite_maintain_config
  end

  def mock_satellite_package_version(satver)
    ForemanMaintain.package_manager.
      expects(:find_installed_package).
      with('satellite', '%{VERSION}').returns(satver)
  end

  describe 'downstream' do
    before do
      ForemanMaintain::Scenarios::SelfUpgrade.any_instance.stubs(:el_major_version).returns(9)
    end

    let(:expected_repos) do
      [
        'rhel-9-for-x86_64-baseos-rpms',
        'rhel-9-for-x86_64-appstream-rpms',
        'satellite-maintenance-6.17-for-rhel-9-x86_64-rpms',
      ]
    end

    it 'with maintain from 6.16 on satellite 6.14.1 raises error' do
      mock_satellite_package_version('6.14.1')
      assume_feature_present(:satellite)

      assert_raises(ForemanMaintain::Error::Warn) do
        ForemanMaintain::Scenarios::SelfUpgrade.new
      end
    end

    it 'with maintain from 6.16 on satellite 6.15.1 upgrades maintain using 6.16 repos' do
      mock_satellite_package_version('6.15.1')
      assume_feature_present(:satellite)

      scenario = ForemanMaintain::Scenarios::SelfUpgrade.new
      scenario.compose

      expected_616_repos = [
        'rhel-9-for-x86_64-baseos-rpms',
        'rhel-9-for-x86_64-appstream-rpms',
        'satellite-maintenance-6.16-for-rhel-9-x86_64-rpms',
      ]
      update_step = scenario.steps.find { |s| s.is_a?(Procedures::Packages::Update) }
      assert update_step, 'Expected a Packages::Update step'
      assert_equal expected_616_repos, update_step.instance_variable_get(:@enabled_repos)
    end

    it 'with maintain from 6.16 on satellite 6.16.1 upgrades maintain to latest from 6.17' do
      mock_satellite_package_version('6.16.1')
      assume_feature_present(:satellite)
      scenario = ForemanMaintain::Scenarios::SelfUpgrade.new
      scenario.compose

      update_step = scenario.steps.find { |s| s.is_a?(Procedures::Packages::Update) }
      assert update_step, 'Expected a Packages::Update step'
      assert_equal expected_repos, update_step.instance_variable_get(:@enabled_repos)
    end

    it 'with maintain from 6.16 on satellite 6.17.1 raises error' do
      mock_satellite_package_version('6.17.1')
      assume_feature_present(:satellite)

      assert_raises(ForemanMaintain::Error::Warn) do
        ForemanMaintain::Scenarios::SelfUpgrade.new
      end
    end

    it 'with Capsule from 6.16 updates by temp-enabling 6.17 repos' do
      ForemanMaintain.package_manager.
        expects(:find_installed_package).
        with('satellite-capsule', '%{VERSION}').returns('6.16.3')
      assume_feature_present(:capsule)
      ForemanMaintain::Scenarios::SelfUpgrade.any_instance.stubs(:el_major_version).returns(9)
      scenario = ForemanMaintain::Scenarios::SelfUpgrade.new
      scenario.compose

      update_step = scenario.steps.find { |s| s.is_a?(Procedures::Packages::Update) }
      assert update_step, 'Expected a Packages::Update step'
      assert_equal expected_repos, update_step.instance_variable_get(:@enabled_repos)
    end
  end

  describe 'upstream' do
    before do
      assume_feature_present(:foreman_install)
    end

    it 'with f-m from 3.11 sets up 3.12 repos' do
      ForemanMaintain.package_manager.stubs(:find_installed_package).
        with('foreman', "%{VERSION}").returns('3.11.0')
      ForemanMaintain.package_manager.stubs(:find_installed_package).
        with('foreman-release', '%{VERSION}').returns('3.11')
      scenario = ForemanMaintain::Scenarios::SelfUpgrade.new
      scenario.compose

      setup_step = scenario.steps.find { |s| s.is_a?(Procedures::Repositories::Setup) }
      assert setup_step, 'Expected a Repositories::Setup step'
      assert_equal '3.12', setup_step.instance_variable_get(:@version)
    end

    it 'with f-m from 3.12 sets up 3.12 repos' do
      ForemanMaintain.package_manager.stubs(:find_installed_package).
        with('foreman', "%{VERSION}").returns('3.12.0')
      ForemanMaintain.package_manager.stubs(:find_installed_package).
        with('foreman-release', '%{VERSION}').returns('3.12')
      scenario = ForemanMaintain::Scenarios::SelfUpgrade.new
      scenario.compose

      setup_step = scenario.steps.find { |s| s.is_a?(Procedures::Repositories::Setup) }
      assert setup_step, 'Expected a Repositories::Setup step'
      assert_equal '3.12', setup_step.instance_variable_get(:@version)
    end
  end
end
