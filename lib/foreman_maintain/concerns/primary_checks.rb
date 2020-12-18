module ForemanMaintain
  module Concerns
    module PrimaryChecks
      def validate_downstream_packages
        package = package_name
        if !package.nil? && detector.feature(:installer).with_scenarios?
          unless package_manager.installed?(package)
            raise StandardError, "Error: Important rpm package #{package} is not installed!"\
                  "\nInstall #{package} rpm to ensure system consistency."
          end
        end
      end

      def package_name
        installed_scenario = detector.feature(:installer).last_scenario
        if installed_scenario == 'satellite'
          'satellite'
        elsif installed_scenario == 'capsule'
          'satellite-capsule'
        end
      end
    end
  end
end
