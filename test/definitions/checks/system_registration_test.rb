require 'test_helper'

describe Checks::SystemRegistration do
  include DefinitionsTestHelper

  subject { Checks::SystemRegistration.new }

  let(:rhsm_conf_file_path) do
    File.expand_path('../../../support/', __FILE__)
  end

  context 'when RH subscription manager conf exists' do
    let(:rhsm_hostname_cmd) { "grep '\\bhostname\\b' < /etc/rhsm/rhsm.conf" }
    before do
      subject.stubs(:file_exists?).returns(true)
    end

    it 'run method executes successfully' do
      subject.expects(:run)
      subject.run
    end

    it 'raises a warning if system is self registerd' do
      subject.stubs(:system_is_self_registerd?).returns(true)

      exception = assert_raises(ForemanMaintain::Error::Warn) { subject.run }
      assert_equal('System is self registered', exception.message)
    end

    it 'no warning raised if system is not self registered' do
      subject.stubs(:system_is_self_registerd?).returns(false)

      result = run_step(subject)
      refute result.warning?
    end

    it 'should match hostname(sat.example.com) when rhsm.conf says hostname = sat.example.com' do
      subject.stubs(:rhsm_conf_file).returns(rhsm_conf_file_path + '/rhsm.conf')
      subject.stubs(:hostname).returns('sat.example.com')
      assert subject.system_is_self_registerd?
    end

    it 'should not match hostname(sat.example.com) \
          when rhsm.conf says hostname = another-sat.example.com' do
      subject.stubs(:rhsm_conf_file).returns(rhsm_conf_file_path + '/rhsm_mismatch.conf')
      subject.stubs(:hostname).returns('sat.example.com')
      refute subject.system_is_self_registerd?
    end

    it 'should match hostname(sat.example.com) when rhsm.conf says hostname=sat.example.com' do
      subject.stubs(:rhsm_conf_file).returns(rhsm_conf_file_path + '/rhsm_no_space.conf')
      subject.stubs(:hostname).returns('sat.example.com')
      assert subject.system_is_self_registerd?
    end

    it 'should not match commented hostname' do
      subject.stubs(:rhsm_conf_file).returns(rhsm_conf_file_path + '/bad_rhsm.conf')
      subject.stubs(:hostname).returns('foreman.example.com')
      refute subject.system_is_self_registerd?
    end
  end

  context 'when RH subscription manager conf does not exists' do
    before do
      subject.stubs(:file_exists?).returns(false)
    end

    it "runs does not executes when rpm 'katello-ca-consumer' is absent" do
      subject.stubs(:execute).with("rpm -qa 'katello-ca-consumer*' | wc -l").returns(0)
      subject.expects(:run)

      subject.run
    end
  end
end
