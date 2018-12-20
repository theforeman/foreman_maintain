require 'test_helper'

module ForemanMaintain
  describe Cli::SystemReport do
    let(:system_report_class) { Cli::SystemReport }

    def stub_output(output)
      system_report_class.any_instance.stubs(:output => output)
    end

    describe '.runner_class' do
      it 'returns Json report runner' do
        stub_output('json')

        assert_equal ForemanMaintain::ReportRunner::Json,
                     system_report_class.new(nil).runner_class
      end

      it 'returns Yaml report runner' do
        stub_output('yaml')

        assert_equal ForemanMaintain::ReportRunner::Yaml,
                     system_report_class.new(nil).runner_class
      end
    end

    describe '.reporter' do
      it 'is kind of PlainTextReporter' do
        assert_kind_of ForemanMaintain::Reporter::PlainTextReporter,
                       system_report_class.new(nil).reporter
      end
    end
  end
end
