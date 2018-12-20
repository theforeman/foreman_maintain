module ForemanMaintain
  module Cli
    class SystemReport < Base
      class << self
        def limit_table_size_option
          option(['-s', '--size'], "['>=1mb'|'<=1MB']",
                 'Show tables with size specified operator(>= or <= or > or <). '\
                 "Defaults to '>=1MB'") do |size|
            size = Report::Params::Size.new(size)
            size.validate!
            size.to_params
          end
        end

        def output_format_option
          option(['-o', '--output'], '[json|plain-text|yaml]',
                 'Specify output format.',
                 :default => 'plain-text') do |output|
            output = Report::Params::Output.new(output)
            output.validate!
            output.to_params
          end
        end
      end

      def run_scenario(scenario)
        if plain_text?
          super(scenario)
        else
          runner_class.new(reporter, scenario).run
        end
      end

      def plain_text?
        output.to_s == 'plain-text'
      end

      def assumeyes?
        false
      end

      def whitelist
        []
      end

      def force?
        false
      end

      def reporter
        @reporter ||= ForemanMaintain::Reporter::PlainTextReporter.new(STDOUT, STDIN)
      end

      def runner_class
        case output
        when 'json' then ForemanMaintain::ReportRunner::Json
        when 'yaml' then ForemanMaintain::ReportRunner::Yaml
        end
      end
    end
  end
end
