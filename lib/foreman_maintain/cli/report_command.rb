module ForemanMaintain
  module Cli
    class ReportCommand < Base
      extend Concerns::Finders

      def generate_report
        scenario = run_scenario(Scenarios::Report::Generate.new({}, [:reports])).first

        # description can be used too
        report_data = scenario.steps.map(&:data).compact.reduce(&:merge).
                      transform_keys(&:to_s).sort.to_h
        report_data['version'] = 2
        report_data
      end

      def save_report(report, file)
        if file
          File.write(file, report)
        else
          puts report
        end
      end

      subcommand 'generate', 'Generates the usage reports' do
        option '--output', 'FILE', 'Output the generate report into FILE'

        def execute
          report_data = generate_report
          yaml = report_data.to_yaml
          save_report(yaml, @output)

          exit runner.exit_code
        end
      end

      subcommand 'condense',
        'Generate a JSON formatted report with condensed data from the original report.' do
        option '--input', 'FILE', 'Input the report from FILE'
        option '--output', 'FILE', 'Output the condense report into FILE'
        option '--max-age', 'HOURS', 'Max age of the report in hours'

        def execute
          data = if fresh_enough?(@input, @max_age)
                   YAML.load_file(@input)
                 else
                   generate_report
                 end

          report = Utils::ReportCondenser.condense_report(data)
          report = prefix_keys(report)
          save_report(JSON.dump(report), @output)
        end

        def prefix_keys(data)
          data.transform_keys { |key| 'foreman.' + key }
        end

        def fresh_enough?(input, max_age)
          @input && File.exist?(input) &&
            (@max_age.nil? || (Time.now - File.stat(input).mtime <= 60 * 60 * max_age.to_i))
        end
      end
    end
  end
end
