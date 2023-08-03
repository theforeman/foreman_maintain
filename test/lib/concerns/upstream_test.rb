require 'test_helper'
require 'minitest/stub_const'

class FakeForemanFeature < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::SystemHelpers
  include ForemanMaintain::Concerns::Upstream
  include ForemanMaintain::Concerns::OsFacts

  def package_name
    'foreman'
  end

  def current_version
    @current_version ||= version('3.2.0')
  end
end

class FakeKatelloFeature < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::SystemHelpers
  include ForemanMaintain::Concerns::Upstream

  def package_name
    'katello'
  end

  def current_version
    @current_version ||= version('4.4.0')
  end
end

module ForemanMaintain
  describe Concerns::Upstream do
    let(:foreman_system) { FakeForemanFeature.new }
    let(:katello_system) { FakeKatelloFeature.new }

    def stub_el(fake_system)
      fake_system.stubs(:el?).returns(true)
      fake_system.stubs(:debian_or_ubuntu?).returns(false)
    end

    def stub_deb(fake_system)
      fake_system.stubs(:el?).returns(false)
      fake_system.stubs(:debian_or_ubuntu?).returns(true)
    end

    def stub_unknown(fake_system)
      fake_system.stubs(:el?).returns(false)
      fake_system.stubs(:debian_or_ubuntu?).returns(false)
    end

    describe '.server_url' do
      it 'returns yum.theforeman.org for EL systems' do
        stub_el(foreman_system)
        foreman_url = 'https://yum.theforeman.org/'
        assert foreman_system.server_url == foreman_url
      end

      it 'returns deb.theforeman.org for Debian or Ubuntu' do
        stub_deb(foreman_system)
        foreman_url = 'https://deb.theforeman.org/'
        assert foreman_system.server_url == foreman_url
      end

      it 'returns failure for non EL and Debian system' do
        stub_unknown(foreman_system)
        assert_raises(RuntimeError) { foreman_system.server_url }
      end
    end

    describe '.foreman_release_pkg_url' do
      it 'returns rpm pkg path when EL' do
        stub_el(foreman_system)
        foreman_system.stubs(:el_short_name).returns('el8')
        pkg_url = 'https://yum.theforeman.org/releases/3.3/el8/x86_64/foreman-release.rpm'
        assert foreman_system.foreman_release_pkg_url('3.3') == pkg_url
      end

      it 'returns deb pkg path when Debian or Ubuntu' do
        stub_deb(foreman_system)
        foreman_system.stubs(:os_version_codename).returns('buster')
        pkg_url = 'https://deb.theforeman.org/pool/buster/3.3'\
          '/f/foreman-release/foreman-release.deb'
        assert foreman_system.foreman_release_pkg_url('3.3') == pkg_url
      end

      it 'returns failure for non EL and Debian system' do
        stub_unknown(foreman_system)
        assert_raises(RuntimeError) { foreman_system.foreman_release_pkg_url('3.3') }
      end
    end

    describe '.katello_release_pkg' do
      it 'returns the katello-repos-latest.rpm path' do
        stub_el(katello_system)
        katello_system.stubs(:el_short_name).returns('el8')
        katello_system.stubs(:katello_version_by_foreman).returns('4.5')
        pkg_url = 'https://yum.theforeman.org/katello/4.5/katello/el8/x86_64/katello-repos-latest.rpm'
        assert katello_system.katello_release_pkg('3.3') == pkg_url
      end
    end

    describe '.update_foreman_release_pkg' do
      it 'calls the EL pkg install on EL system' do
        stub_el(foreman_system)
        pkg_url = 'https://fakeurl.org/foreman-release.rpm'
        foreman_system.stubs(:foreman_release_pkg_url).with('3.3').returns(pkg_url)
        foreman_system.expects(:update_release_pkg_el).with(pkg_url)
        foreman_system.expects(:update_release_pkg_deb).with(pkg_url).never
        foreman_system.update_foreman_release_pkg('3.3')
      end

      it 'calls the Debian pkg install on Debian system' do
        stub_deb(foreman_system)
        pkg_url = 'https://fakeurl.org/foreman-release.deb'
        foreman_system.stubs(:foreman_release_pkg_url).with('3.3').returns(pkg_url)
        foreman_system.expects(:update_release_pkg_el).with(pkg_url).never
        foreman_system.expects(:update_release_pkg_deb).with(pkg_url)
        foreman_system.update_foreman_release_pkg('3.3')
      end
    end

    describe '.update_katello_release_pkg' do
      it 'update Katello pkg only for Katello feature' do
        stub_el(katello_system)
        katello_system.stubs(:feature).with(:katello).returns(true)
        pkg_url = 'https://fakeurl.org/katello-repos-latest.rpm'
        katello_system.stubs(:katello_release_pkg).with('3.3').returns(pkg_url)
        katello_system.expects(:update_release_pkg_el).with(pkg_url)
        katello_system.update_katello_release_pkg('3.3')
      end
    end

    describe '.setup repositories' do
      it 'get repositories via activation key' do
        stub_el(foreman_system)
        env_hash = { 'ACTIVATION_KEY' => 'test_key', 'FOREMAN_ORG' => 'test_org' }
        env = ENV.to_hash.merge(env_hash)
        Object.stub_const(:ENV, env) do
          activation_key = ENV['ACTIVATION_KEY']
          org = ENV['FOREMAN_ORG']
          foreman_system.expects(:use_activation_key).with(activation_key, org)
          foreman_system.expects(:update_foreman_release_pkg).with('3.3').never
          foreman_system.expects(:update_katello_release_pkg).with('3.3').never
          foreman_system.setup_repositories('3.3')
        end
      end
    end

    describe '.repoids_and_urls' do
      it 'returns repositories matching with regex' do
        stub_el(katello_system)
        katello_repo_url = 'https://yum.theforeman.org/katello/4.5/katello/el8/x86_64/'
        repository_manager_obj = Minitest::Mock.new
        system_repositories = { 'non_foreman' => 'abc.example.com',
                                'katello' =>  katello_repo_url }
        repository_manager_obj.expect(:enabled_repos, system_repositories)
        ForemanMaintain.stubs(:repository_manager).returns(repository_manager_obj)
        assert katello_system.repoids_and_urls == { 'katello' => katello_repo_url }
      end
    end
  end
end
