module ForemanMaintain
  module Cli
    class ReportCommand < Base
      extend Concerns::Finders

      def generate_report
        scenario = run_scenario(Scenarios::Report::Generate.new({}, [:reports])).first

        # description can be used too
        report_data = scenario.steps.map(&:data).compact.reduce(&:merge).transform_keys(&:to_s)
        report_data['version'] = 1
        report_data
      end

      def save_report(report, file)
        if file
          File.write(file, report)
        else
          puts report
        end
      end

      option '--output', 'FILE', 'Output the generate report into FILE'
      subcommand 'generate', 'Generates the usage reports' do
        def execute
          report_data = generate_report
          yaml = report_data.to_yaml
          save_report(yaml, @output)

          exit runner.exit_code
        end
      end

      option '--input', 'FILE', 'Input the report from FILE'
      option '--output', 'FILE', 'Output the condense report into FILE'
      option '--max-age', 'HOURS', 'Max age of the report in hours'
      subcommand 'condense', 'Condense the report' do
        def execute
          data = if fresh_enough?(@input, @max_age)
            YAML.load_file(@input)
          else
            generate_report
          end

          report = condense_report(data)
          report = prefix_keys(report)
          save_report(JSON.dump(report), @output)
        end

        def condense_report(data)
          result = data.slice('advisor_on_prem_remediations', 'rhel_ai_workload_host_count')
          result.merge!(aggregate_host_count(data))
          result.merge!(aggregate_image_mode_host_count(data))
          result.merge!(aggregate_networking_metrics(data))
          result
        end

        # Aggregates the host count numbers. The goal is to distinguish
        # - RHEL hosts
        # - RedHat family but not RHEL hosts
        # - Other hosts
        def aggregate_host_count(data)
          result = {}
          result['host_rhel_count'] = data['hosts_by_os_count|RedHat']
          result['host_redhat_count'] = data['hosts_by_family_count|Redhat'] - data['hosts_by_os_count|RedHat']
          result['host_other_count'] = data.select { |k, _| k.start_with?('hosts_by_os_count') }.values.sum - result['host_rhel_count'] - result['host_redhat_count']
          result
        end

        def aggregate_image_mode_host_count(data)
          count = data.select { |k, _| k.start_with?('image_mode_hosts_by_os_count') }.values.sum
          { 'image_mode_host_count' => count }
        end

        def aggregate_networking_metrics(data)
          ipv6 = data.values_at('subnet_ipv6_count', 'hosts_with_ipv6only_interface_count', 'foreman_interfaces_ipv6only_count').map { |v| v || 0 }.any?(&:positive?)

          # Deployment is considered to run in dualstack mode if:
          # - Foreman has both ipv6 and ipv4 addresses on a single interface
          # - or if any host in Foreman has both ipv6 and ipv4 addresses on a single interface
          dualstack = data.values_at('hosts_with_dualstack_interface_count', 'foreman_interfaces_dualstack_count').map { |v| v || 0 }.any?(&:positive?)
          # - or if there are both ipv4 and ipv6 subnets defined
          dualstack |= data.values_at('subnet_ipv4_count', 'subnet_ipv6_count').map { |v| v || 0 }.all?(&:positive?)
          # - or if any host in Foreman has an interface with only an ipv4 address as well as another interface with ipv6 address
          dualstack |= data.values_at('hosts_with_ipv4only_interface_count', 'hosts_with_ipv6only_interface_count').map { |v| v || 0 }.all?(&:positive?)
          # - Foreman has an interface with only an ipv4 address as well as another interface with ipv6 address
          dualstack |= data.values_at('foreman_interfaces_ipv4only_count', 'foreman_interfaces_ipv6only_count').map { |v| v || 0 }.all?(&:positive?)

          { 'use_dualstack' => dualstack, 'use_ipv6' => ipv6 }
        end

        def prefix_keys(data)
          data.transform_keys { |key| 'foreman.' + key }
        end

        def fresh_enough?(input, max_age)
          @input && File.exists?(input) &&
            (@max_age.nil? || (Time.now - File.stat(input).mtime <= 60 * 60 * max_age.to_i))
        end
      end
    end
  end
end
