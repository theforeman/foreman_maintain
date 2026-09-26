require 'test_helper'
require 'minitest/stub_const'

require 'foreman_maintain/cli'

module ForemanMaintain
  describe Cli::ReportCommand do
    include CliAssertions
    let :command do
      %w[report]
    end

    it 'prints help' do
      assert_cmd <<~OUTPUT, :ignore_whitespace => true
        Usage:
            foreman-maintain report [OPTIONS] SUBCOMMAND [ARG] ...

        Parameters:
            SUBCOMMAND    subcommand
            [ARG] ...     subcommand arguments

        Subcommands:
            generate      Generates the usage reports
            condense      Generate a JSON formatted report with condensed data from the original report.

        Options:
            -h, --help    print help
      OUTPUT
    end

    describe 'generate' do
      let :command do
        %w[report generate]
      end

      it 'prints help' do
        assert_cmd <<~OUTPUT, %w[-h], :ignore_whitespace => true
          Usage:
              foreman-maintain report generate [OPTIONS]

          Options:
              --output FILE    Output the generate report into FILE
              --quiet          Suppress progress output and only print the report
              -h, --help       print help
        OUTPUT
      end

      it 'suppresses reporter output in quiet mode' do
        step = stub(:data => { 'foo' => 'bar' })
        scenario = stub(:steps => [step])
        runner = stub(:run => [scenario], :exit_code => 0)
        generate = Class.new
        generate.stubs(:new).returns(scenario)
        report = Module.new
        report.const_set(:Generate, generate)

        Runner.expects(:new).with do |reporter, _scenarios, _options|
          reporter.instance_of?(Reporter)
        end.returns(runner)

        Scenarios.stub_const(:Report, report) do
          assert_cmd <<~OUTPUT, %w[--quiet]
            ---
            foo: bar
            version: 3
          OUTPUT
        end
      end
    end

    describe 'condense' do
      let :command do
        %w[report condense]
      end

      it 'prints helps' do
        assert_cmd <<~OUTPUT, %w[-h], :ignore_whitespace => true
          Usage:
              foreman-maintain report condense [OPTIONS]

          Options:
              --input FILE       Input the report from FILE
              --output FILE      Output the condense report into FILE
              --max-age HOURS    Max age of the report in hours
              --quiet            Suppress progress output and only print the report
              -h, --help         print help
        OUTPUT
      end
    end
  end
end
