require 'test_helper'

describe Features::Installer do
  include DefinitionsTestHelper

  subject { Features::Installer.new }
  let(:data_dir) { File.join(File.dirname(__FILE__), '../../data') }
  let(:installer_inst) { Features::Installer.any_instance }

  context 'installer with scenarios' do
    before do
      installer_config_dir(["#{data_dir}/installer/simple_config"])
      mock_installer_package('foreman-installer')
    end

    it 'loads list of configs on the start' do
      expected_config_files = [
        "#{data_dir}/installer/simple_config/scenarios.d",
        "#{data_dir}/installer/simple_config/scenarios.d/foreman-answers.yaml",
        "#{data_dir}/installer/simple_config/scenarios.d/foreman.yaml",
        "#{data_dir}/installer/simple_config/scenarios.d/last_scenario.yaml",
        '/usr/local/bin/validate_postgresql_connection.sh'
      ].sort
      subject.config_files.sort.must_equal(expected_config_files)
    end

    it 'can tell if we use scenarios or not' do
      subject.with_scenarios?.must_equal true
    end

    it 'can tell last used scenario from the link' do
      subject.last_scenario.must_equal('foreman')
    end

    it 'returns the last scenario answers as a hash' do
      subject.answers['foreman']['admin_password'].must_equal('inspasswd')
    end

    it 'has --upgrade' do
      subject.can_upgrade?.must_equal true
    end

    context '#upgrade' do
      it '#upgrade runs the installer with correct params' do
        assume_feature_absent(:satellite)
        installer_inst.expects(:'execute!').
          with('LANG=en_US.utf-8 foreman-installer --upgrade', :interactive => true).
          returns(true)
        subject.upgrade(:interactive => true)
      end

      it '#upgrade runs the installer with correct params in satellite' do
        assume_feature_present(:satellite)
        installer_inst.expects(:'execute!').
          with('LANG=en_US.utf-8 satellite-installer --upgrade', :interactive => true).
          returns(true)
        subject.upgrade(:interactive => true)
      end
    end

    context '#run' do
      it 'runs the installer with correct params' do
        assume_feature_absent(:satellite)
        installer_inst.expects(:'execute!').
          with('LANG=en_US.utf-8 foreman-installer --password=changeme', :interactive => true).
          returns(true)
        subject.run('--password=changeme', :interactive => true)
      end

      it 'runs the installer with correct params in satellite' do
        assume_feature_present(:satellite)
        installer_inst.expects(:'execute!').
          with('LANG=en_US.utf-8 satellite-installer --password=changeme', :interactive => true).
          returns(true)
        subject.run('--password=changeme', :interactive => true)
      end
    end
  end

  context 'legacy katello installer without scenarios (6.1)' do
    before do
      installer_config_dir(["#{data_dir}/installer/katello-installer"])
      mock_installer_package('katello-installer')
    end

    it 'loads list of configs on the start' do
      expected_config_files = [
        "#{data_dir}/installer/katello-installer/answers.capsule-certs-generate.yaml",
        "#{data_dir}/installer/katello-installer/answers.katello-installer.yaml",
        "#{data_dir}/installer/katello-installer/capsule-certs-generate.yaml",
        "#{data_dir}/installer/katello-installer/config_header.txt",
        "#{data_dir}/installer/katello-installer/katello-installer.yaml",
        '/usr/local/bin/validate_postgresql_connection.sh'
      ].sort
      subject.config_files.sort.must_equal(expected_config_files)
    end

    it 'can tell if we use scenarios or not' do
      subject.with_scenarios?.must_equal false
    end

    it 'can tell last used scenario from the link' do
      subject.last_scenario.must_be_nil
    end

    it 'returns the answers as a hash' do
      subject.answers['foreman']['admin_password'].must_equal('changeme')
    end

    it 'has --upgrade' do
      subject.can_upgrade?.must_equal true
    end

    context '#upgrade' do
      it 'runs the installer with correct params' do
        installer_inst.expects(:'execute!').
          with('LANG=en_US.utf-8 katello-installer --upgrade', :interactive => true).
          returns(true)
        subject.upgrade(:interactive => true)
      end
    end

    context '#run' do
      it 'runs the installer with correct params' do
        installer_inst.expects(:'execute!').
          with('LANG=en_US.utf-8 katello-installer --password=changeme', :interactive => true).
          returns(true)
        subject.run('--password=changeme', :interactive => true)
      end
    end
  end

  context 'legacy capsule installer without scenarios (6.1)' do
    before do
      installer_config_dir(["#{data_dir}/installer/capsule-installer"])
      mock_installer_package('capsule-installer')
    end

    it 'loads list of configs on the start' do
      expected_config_files = [
        "#{data_dir}/installer/capsule-installer/answers.capsule-installer.yaml",
        "#{data_dir}/installer/capsule-installer/capsule-installer.yaml",
        "#{data_dir}/installer/capsule-installer/config_header.txt",
        '/usr/local/bin/validate_postgresql_connection.sh'
      ].sort
      subject.config_files.sort.must_equal(expected_config_files)
    end

    it 'can tell if we use scenarios or not' do
      subject.with_scenarios?.must_equal false
    end

    it 'returns the answers as a hash' do
      subject.answers['certs']['deploy'].must_equal(true)
    end

    it 'does not have --upgrade' do
      subject.can_upgrade?.must_equal false
    end

    context '#upgrade' do
      it 'runs the installer with correct params' do
        installer_inst.expects(:'execute!').
          with('LANG=en_US.utf-8 capsule-installer', :interactive => true).
          returns(true)
        subject.upgrade(:interactive => true)
      end
    end

    context '#run' do
      it 'runs the installer with correct params' do
        installer_inst.expects(:'execute!').
          with('LANG=en_US.utf-8 capsule-installer --certs=true', :interactive => true).
          returns(true)
        subject.run('--certs=true', :interactive => true)
      end
    end
  end
end
