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
      Features::Installer.any_instance.
        stubs(:installer_arguments).returns('--disable-system-checks --upgrade')
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
          with('LANG=en_US.utf-8 foreman-installer --disable-system-checks --upgrade',
               :interactive => true).
          returns(true)
        subject.upgrade(:interactive => true)
      end

      it '#upgrade runs the installer with correct params in satellite' do
        assume_feature_present(:satellite)
        installer_inst.expects(:'execute!').
          with('LANG=en_US.utf-8 satellite-installer --disable-system-checks --upgrade',
               :interactive => true).
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
end
