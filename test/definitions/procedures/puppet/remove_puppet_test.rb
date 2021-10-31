require 'test_helper'

describe Procedures::Puppet::RemovePuppet do
  include DefinitionsTestHelper

  subject do
    Procedures::Puppet::RemovePuppet.new
  end

  before do
    mock_installer_package('foreman-installer')
  end

  describe '#installer_arguments_disabling_puppet' do
    it 'works for foreman default' do
      stub_installer_answers('foreman-answers-default.yaml')
      expected_arguments = [
        '--no-enable-foreman-cli-puppet',
        '--no-enable-foreman-plugin-puppet',
        '--foreman-proxy-puppet false',
        '--foreman-proxy-puppetca false',
        '--no-enable-puppet'
      ]
      _(subject.send(:installer_arguments_disabling_puppet).sort).must_equal expected_arguments.sort
    end

    it 'works for proxy with puppet' do
      stub_installer_answers('foreman-answers-no-foreman-with-puppet.yaml')
      expected_arguments = [
        '--foreman-proxy-puppet false',
        '--foreman-proxy-puppetca false',
        '--no-enable-puppet'
      ]
      _(subject.send(:installer_arguments_disabling_puppet).sort).must_equal expected_arguments.sort
    end

    it 'works for katello' do
      stub_installer_answers('katello-answers-with-puppet.yaml')
      expected_arguments = [
        '--no-enable-foreman-cli-puppet',
        '--no-enable-foreman-plugin-puppet',
        '--foreman-proxy-puppet false',
        '--foreman-proxy-puppetca false',
        '--foreman-proxy-content-puppet false',
        '--no-enable-puppet'
      ]
      _(subject.send(:installer_arguments_disabling_puppet).sort).must_equal expected_arguments.sort
    end

    it 'works for proxy-content' do
      stub_installer_answers('foreman-proxy-content-with-puppet.yaml')
      expected_arguments = [
        '--foreman-proxy-puppet false',
        '--foreman-proxy-puppetca false',
        '--foreman-proxy-content-puppet false',
        '--no-enable-puppet'
      ]
      _(subject.send(:installer_arguments_disabling_puppet).sort).must_equal expected_arguments.sort
    end
  end

  def stub_installer_answers(filename)
    file = "test/data/puppet/#{filename}"
    assume_feature_present(:installer, configuration: { answer_file: file })
  end
end
