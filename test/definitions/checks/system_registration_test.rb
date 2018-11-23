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

    context 'raise error' do
      let(:msg) { '[Server] expected to raise error' }

      it 'system is self registered' do
        assume_feature_present(:capsule)

        subject.stubs(:rhsm_hostname).returns('sat.example.com')
        subject.stubs(:hostname).returns('sat.example.com')
        result = run_step(subject)

        assert result.fail?, msg
      end

      it 'hostname is sat.example.com & rhsm.conf contains hostname=sat.example.com' do
        assume_satellite_present
        subject.stubs(:rhsm_conf_file).returns(rhsm_conf_file_path + '/rhsm_no_space.conf')
        subject.stubs(:hostname).returns('sat.example.com')
        result = run_step(subject)

        assert result.fail?, msg
      end

      it 'hostname is sat.example.com & rhsm.conf contains hostname = sat.example.com' do
        subject.stubs(:rhsm_conf_file).returns(rhsm_conf_file_path + '/rhsm.conf')
        subject.stubs(:hostname).returns('sat.example.com')
        result = run_step(subject)

        assert result.fail?, msg
      end
    end

    context 'do not raise error' do
      let(:msg) { '[Server] expected NOT to raise error' }

      it 'hostname is sat.example.com & rhsm.conf contains hostname = another-sat.example.com' do
        assume_satellite_present
        subject.stubs(:rhsm_conf_file).returns(rhsm_conf_file_path + '/rhsm_mismatch.conf')
        subject.stubs(:hostname).returns('sat.example.com')
        result = run_step(subject)

        refute result.fail?, msg
      end

      it 'hostname commented' do
        assume_satellite_present
        subject.stubs(:rhsm_conf_file).returns(rhsm_conf_file_path + '/bad_rhsm.conf')
        subject.stubs(:hostname).returns('foreman.example.com')
        result = run_step(subject)

        refute result.fail?, msg
      end
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
