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

    assert_equal '6.16', scenario.target_version
  end

  it 'returns target version correctly for upstream' do
    assume_feature_present(:foreman_install)

    assert_equal '3.11', scenario.target_version
  end

  it 'allow upgrade when versions are equal' do
    assume_satellite_present
    scenario.expects(:current_version).returns('6.16.0')

    assert scenario.self_upgrade_allowed?
  end

  it 'allow upgrade when versions are equal for z-stream' do
    assume_satellite_present
    scenario.expects(:current_version).returns('6.16.4')

    assert scenario.self_upgrade_allowed?
  end

  it 'allow upgrade when versions are off by 1' do
    assume_satellite_present
    scenario.expects(:current_version).twice.returns('6.15.8')

    assert scenario.self_upgrade_allowed?
  end

  it 'does not allow upgrade when versions are off by 2 or more' do
    assume_satellite_present
    scenario.expects(:current_version).twice.returns('6.14.4')

    refute scenario.self_upgrade_allowed?
  end
end

describe ForemanMaintain::Scenarios::SelfUpgrade do
  include ::DefinitionsTestHelper

  before do
    File.stubs(:exist?).with('/etc/redhat-release').returns(true)
    mock_satellite_maintain_config
  end

  it 'runs successfully for downstream Satellite' do
    ForemanMaintain.
      package_manager.
      expects(:find_installed_package).
      with('satellite', "%{VERSION}").
      returns('6.16.0')
    assume_feature_present(:satellite)
    scenario = ForemanMaintain::Scenarios::SelfUpgrade.new
    scenario.compose

    assert run_step(scenario)
  end

  it 'runs successfully for downstream Capsule' do
    ForemanMaintain.
      package_manager.
      expects(:find_installed_package).
      with('satellite-capsule', "%{VERSION}").
      returns('6.16.3')
    assume_feature_present(:capsule)
    scenario = ForemanMaintain::Scenarios::SelfUpgrade.new
    scenario.compose

    assert run_step(scenario)
  end

  it 'run successfully if current and target version are off by 1' do
    ForemanMaintain.
      package_manager.
      expects(:find_installed_package).
      with('satellite', "%{VERSION}").
      returns('6.15.3')
    assume_feature_present(:satellite)
    scenario = ForemanMaintain::Scenarios::SelfUpgrade.new
    scenario.compose

    assert run_step(scenario)
  end

  it 'fails if versions are off 2 or more' do
    ForemanMaintain.
      package_manager.
      expects(:find_installed_package).
      with('satellite', "%{VERSION}").
      returns('6.14.1')
    assume_feature_present(:satellite)

    msg = "foreman-maintain is too many versions ahead. The target " \
          "version is 6.16 while the currently installed " \
          "version is 6.14.1. Please rollback " \
          "foreman-maintain to the proper version."
    assert_raises(ForemanMaintain::Error::Warn, msg) do
      scenario = ForemanMaintain::Scenarios::SelfUpgrade.new
      scenario.compose
    end
  end
end
