require 'test_helper'

require 'foreman_maintain/cli'

module ForemanMaintain
  describe Cli::ReportCommand do
    include CliAssertions

    let :command do
      %w[report]
    end

    it 'prints help - lists all available commands for report' do
      assert_cmd <<-OUTPUT.strip_heredoc
        Usage:
            foreman-maintain report [OPTIONS] SUBCOMMAND [ARG] ...

        Parameters:
            SUBCOMMAND                    subcommand
            [ARG] ...                     subcommand arguments

        Subcommands:
            disk-usage                    Report disk consumption and availability of directories
            table-counts                  Get table counts
            table-sizes                   Get table sizes
            all                           Generate all reports

        Options:
            -h, --help                    print help
      OUTPUT
    end

    describe 'report all help' do
      let :command do
        %w[report all --help]
      end

      it 'prints help options for all reports' do
        assert_cmd <<-OUTPUT.strip_heredoc
          Usage:
              foreman-maintain report all [OPTIONS]

          Options:
              -o, --output [json|plain-text|yaml] Specify output format. (default: "plain-text")
              -h, --help                    print help
        OUTPUT
      end
    end

    describe 'report table-sizes help' do
      let :command do
        %w[report table-sizes --help]
      end

      it 'prints help options for table-sizes' do
        assert_cmd <<-OUTPUT.strip_heredoc
          Usage:
              foreman-maintain report table-sizes [OPTIONS]

          Options:
              -o, --output [json|plain-text|yaml] Specify output format. (default: "plain-text")
              -s, --size ['>=1mb'|'<=1MB']  Show tables with size specified operator(>= or <= or > or <). Defaults to '>=1MB'
              -h, --help                    print help
        OUTPUT
      end
    end

    describe 'report table-sizes with size option' do
      let :command do
        %w[report table-sizes --size=<1m]
      end

      it 'should execute successfully' do
        Cli::ReportCommand.any_instance.expects(:run_scenario)
        assert_equal '', run_cmd
      end
    end

    describe 'report table-counts with output option' do
      let :command do
        %w[report table-counts --output=json]
      end

      it 'should execute successfully' do
        Cli::ReportCommand.any_instance.expects(:run_scenario)
        assert_equal '', run_cmd
      end
    end
  end
end
