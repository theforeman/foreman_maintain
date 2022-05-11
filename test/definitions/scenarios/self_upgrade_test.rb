require 'test_helper'

module Scenarios
  describe ForemanMaintain::Scenarios::SelfUpgrade do
    include DefinitionsTestHelper

    let(:scenario) do
      ForemanMaintain::Scenarios::SelfUpgrade.new
    end

    describe 'using CDN' do
      it 'reenables maintenance repo' do
        scenario.stubs(:stored_enabled_repos_ids).returns([])
        scenario.stubs(:current_version).returns('6.10')
        scenario.stubs(:el_major_version).returns(7)
        assert_equal ['rhel-7-server-satellite-maintenance-6-rpms'], scenario.repos_ids_to_reenable
      end
    end

    describe 'using custom repos' do
      it 'does not reenable maintenance repo if it was disabled' do
        scenario.stubs(:stored_enabled_repos_ids).returns([])
        scenario.stubs(:current_version).returns('6.10')
        scenario.stubs(:el_major_version).returns(7)
        scenario.stubs(:maintenance_repo_label).returns('custom-maintenance')
        assert_equal [], scenario.repos_ids_to_reenable
      end

      it 'reenables maintenance repo if it was enabled' do
        scenario.stubs(:stored_enabled_repos_ids).returns(['custom-maintenance'])
        scenario.stubs(:current_version).returns('6.10')
        scenario.stubs(:el_major_version).returns(7)
        scenario.stubs(:maintenance_repo_label).returns('custom-maintenance')
        assert_equal ['custom-maintenance'], scenario.repos_ids_to_reenable
      end
    end
  end
end
