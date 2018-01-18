require 'test_helper'

module ForemanMaintain
  describe Utils::Distros::RedHat do
    let :redhat do
      Utils::Distros::RedHat.new
    end

    let :expected_repo_url do
      'https://yum.theforeman.org/releases/1.15/el7/x86_64/foreman-release.rpm'
    end

    it 'returns expected upstream_repo' do
      redhat.stubs(:upgrade_version).returns('1.15')
      assert_equal expected_repo_url, redhat.upstream_repo
    end
  end
end
