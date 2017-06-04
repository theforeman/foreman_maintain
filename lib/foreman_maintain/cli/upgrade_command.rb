module ForemanMaintain
  module Cli
    class UpgradeCommand < Base
      def tags_to_versions
        { :satellite_6_0_z => '6.0.z',
          :satellite_6_1 => '6.1',
          :satellite_6_1_z => '6.1.z',
          :satellite_6_2 => '6.2',
          :satellite_6_2_z => '6.2.z',
          :satellite_6_3 => '6.3' }
      end

      # We search for scenarios available for the system and determine
      # user-friendly version numbers for it.
      # This method returns a hash of mapping the versions to scenarios to run
      # The tag is determining which kind of scenario we're searching for
      # (such as pre_upgrade_check)
      def available_target_versions(tag)
        conditions = { :tags => [tag] }
        find_scenarios(conditions).inject({}) do |hash, scenario|
          # find tag that represent the version upgrade
          version_tag = scenario.tags.find { |t| tags_to_versions.key?(t) }
          if version_tag
            hash.update(tags_to_versions[version_tag] => scenario)
          else
            hash
          end
        end
      end

      def find_scenario(tag)
        available_target_versions(tag)[target_version]
      end

      def print_versions(target_versions)
        target_versions.keys.sort.each { |version| puts version }
      end

      subcommand 'list-versions', 'List versions this system is upgradable to' do
        def execute
          print_versions(available_target_versions(:pre_upgrade_checks))
        end
      end

      subcommand 'check', 'Run pre-upgrade checks for upgrading to specified version' do
        parameter 'TARGET_VERSION', 'Target version of the upgrade', :required => false
        interactive_option

        def execute
          versions_to_scenarios = available_target_versions(:pre_upgrade_checks)
          scenario = versions_to_scenarios[target_version]
          if scenario
            run_scenario(scenario)
          else
            puts "The specified version #{target_version} is unavailable"
            puts 'Possible target versions are:'
            print_versions(versions_to_scenarios)
          end
        end
      end

      subcommand 'run', 'Run full upgrade to a specified version' do
        parameter 'TARGET_VERSION', 'Target version of the upgrade', :required => false
        interactive_option

        def execute
          scenarios = [find_scenario(:pre_upgrade_checks),
                       find_scenario(:pre_migrations),
                       find_scenario(:migrations),
                       find_scenario(:post_migrations),
                       find_scenario(:post_upgrade_checks)].compact
          if scenarios.empty?
            puts "The specified version #{target_version} is unavailable"
            puts 'Possible target versions are:'
            print_versions(available_target_versions(:pre_upgrade_checks))
          else
            run_scenario(scenarios)
          end
        end
      end
    end
  end
end
