require 'test_helper'

describe Features::CandlepinDatabase do
  include DefinitionsTestHelper
  subject { Features::CandlepinDatabase.new }

  let(:cp_config_dir) do
    File.expand_path('../../support', __dir__)
  end

  def stub_config(&block)
    subject.stub(:raw_config, File.read(File.join(cp_config_dir, config)), &block)
  end

  describe '.configuration' do
    let(:configuration) { subject.configuration }

    describe 'with ssl' do
      let(:config) { 'candlepin_with_ssl.conf' }

      it 'sets ssl to true' do
        stub_config do
          assert_includes configuration['url'], 'ssl=true'
          assert configuration['ssl']
        end
      end
    end

    describe 'without ssl' do
      let(:config) { 'candlepin_without_ssl.conf' }

      it 'sets ssl to false' do
        stub_config do
          refute_includes configuration['url'], 'ssl=true'
          refute configuration['ssl']
        end
      end
    end
  end
end
