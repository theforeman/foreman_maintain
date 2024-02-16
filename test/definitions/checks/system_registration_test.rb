require 'test_helper'

describe Checks::SystemRegistration do
  include DefinitionsTestHelper

  subject { Checks::SystemRegistration.new }

  let(:rhsm_conf_file_path) do
    File.expand_path('../../support', __dir__)
  end

  context 'when RH subscription manager conf exists' do
    let(:rhsm_hostname_cmd) { "grep '\\bhostname\\b' < /etc/rhsm/rhsm.conf" }

    before do
      subject.class.stubs(:file_exists?).returns(true)
      subject.class.expects(:present?).returns(true)
    end

    context 'smart-proxy' do
      before do
        assume_feature_present(:foreman_server, :present? => false)
        assume_feature_present(:foreman_proxy, :present? => true)
      end

      context 'raise warning' do
        let(:msg) { '[Server] expected to raise warning' }

        it 'system is self registered' do
          subject.stubs(:rhsm_hostname_eql_hostname?).returns(true)
          result = run_step(subject)

          assert result.warning?, msg
        end

        it 'hostname is sat.example.com & rhsm.conf contains hostname=sat.example.com' do
          subject.stubs(:rhsm_conf_file).returns(rhsm_conf_file_path + '/rhsm_no_space.conf')
          subject.stubs(:hostname).returns('sat.example.com')
          result = run_step(subject)

          assert result.warning?, msg
        end

        it 'hostname is sat.example.com & rhsm.conf contains hostname = sat.example.com' do
          subject.stubs(:rhsm_conf_file).returns(rhsm_conf_file_path + '/rhsm.conf')
          subject.stubs(:hostname).returns('sat.example.com')
          result = run_step(subject)

          assert result.warning?, msg
        end
      end

      context 'do not raise warning' do
        let(:msg) { '[Server] expected NOT to raise warning' }

        it 'hostname is sat.example.com & rhsm.conf contains hostname = another-sat.example.com' do
          subject.stubs(:rhsm_conf_file).returns(rhsm_conf_file_path + '/rhsm_mismatch.conf')
          subject.stubs(:hostname).returns('sat.example.com')
          result = run_step(subject)

          refute result.warning?, msg
        end

        it 'hostname commented' do
          subject.stubs(:rhsm_conf_file).returns(rhsm_conf_file_path + '/bad_rhsm.conf')
          subject.stubs(:hostname).returns('foreman.example.com')
          result = run_step(subject)

          refute result.warning?, msg
        end
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
