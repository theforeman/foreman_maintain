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
        '/opt/puppetlabs/puppet/cache/foreman_cache_data',
        '/opt/puppetlabs/puppet/cache/pulpcore_cache_data',
      ].sort
      _(subject.config_files.sort).must_equal(expected_config_files)
    end

    it 'can tell last used scenario from the link' do
      _(subject.last_scenario).must_equal('foreman')
    end

    it 'returns the last scenario answers as a hash' do
      _(subject.answers['foreman']['admin_password']).must_equal('inspasswd')
    end

    context '#run' do
      it 'runs the installer with correct params' do
        assume_feature_absent(:satellite)
        installer_inst.expects(:'execute!').
          with('foreman-installer --password=changeme', { :interactive => true }).
          returns(true)
        subject.run('--password=changeme', :interactive => true)
      end

      it 'runs the installer with correct params in satellite' do
        assume_feature_present(:satellite)
        installer_inst.expects(:'execute!').
          with('satellite-installer --password=changeme', { :interactive => true }).
          returns(true)
        subject.run('--password=changeme', :interactive => true)
      end
    end
  end
end
