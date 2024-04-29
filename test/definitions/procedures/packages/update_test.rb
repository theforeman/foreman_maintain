require 'test_helper'

describe Procedures::Packages::Update do
  include DefinitionsTestHelper

  def skip_mock_package_manager
    true
  end

  describe 'Update packages with download only for Dnf' do
    subject do
      Procedures::Packages::Update.new(:assumeyes => true, :download_only => true)
    end

    def setup
      dnf = ForemanMaintain::PackageManager::Dnf.new
      dnf.sys.expects(:execute!).with(
        'dnf -y --downloadonly --disableplugin=foreman-protector update',
        :interactive => false,
        :valid_exit_statuses => [0]
      )
      dnf.sys.expects(:execute!).with(
        'dnf -y --disableplugin=foreman-protector clean metadata',
        :interactive => false,
        :valid_exit_statuses => [0]
      )
      ForemanMaintain.stubs(:package_manager).returns(dnf)
      super
    end

    it 'downloads package updates only on Enterprise Linux' do
      result = run_procedure(subject)
      assert result.success?, 'the procedure was expected to succeed'
    end
  end

  describe 'Update packages with download only for Debian' do
    subject do
      Procedures::Packages::Update.new(:assumeyes => true, :download_only => true)
    end

    def setup
      apt = ForemanMaintain::PackageManager::Apt.new
      apt.sys.expects(:execute!).with(
        'apt-get -y clean',
        :interactive => false,
        :valid_exit_statuses => [0]
      )
      apt.sys.expects(:execute!).with(
        'apt-get -y --download-only upgrade',
        :interactive => false,
        :valid_exit_statuses => [0]
      )
      ForemanMaintain.stubs(:package_manager).returns(apt)
      super
    end

    it 'downloads package updates only on Debian' do
      result = run_procedure(subject)
      puts result.output
      assert result.success?, 'the procedure was expected to succeed'
    end
  end
end
