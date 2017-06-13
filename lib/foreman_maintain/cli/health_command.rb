module ForemanMaintain
  module Cli
    class HealthCommand < Base
      subcommand 'list', 'List the checks based on criteria' do
        tags_option

        def execute
          DependencyGraph.sort(available_checks.map(&:ensure_instance)).each do |check|
            print_check_info(check)
          end
        end

        def print_check_info(check)
          desc = "#{label_string(check.label)} #{check.description}".ljust(80)
          tags = check.tags.map { |t| tag_string(t) }.join(' ').to_s
          puts "#{desc} #{tags}"
        end
      end

      subcommand 'list-tags', 'List the tags to use for filtering checks' do
        def execute
          available_tags(available_checks).each { |tag| puts tag_string(tag) }
        end

        def print_check_info(check)
          desc = "#{label_string(check.label)} #{check.description}".ljust(80)
          tags = check.tags.map { |t| tag_string(t) }.join(' ').to_s
          puts "#{desc} #{tags}"
        end
      end

      subcommand 'check', 'Run the health checks against the system' do
        label_option
        tags_option
        interactive_option

        def execute
          scenario = Scenario::FilteredScenario.new(filter)
          if scenario.steps.empty?
            puts "No scenario matching #{humanized_filter}"
            exit 1
          else
            run_scenario(scenario)
          end
        end

        def filter
          if label
            { :label => label }
          else
            { :tags => tags || [:default] }
          end
        end

        def humanized_filter
          if label
            "label #{label_string(filter[:label])}"
          else
            "tags #{filter[:tags].map { |tag| tag_string(tag) }.join}"
          end
        end
      end
    end
  end
end
