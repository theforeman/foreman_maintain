module ForemanMaintain
  module Concerns
    module PrimaryChecks
      def validate_downstream_packages
        return unless detector.feature(:installer) && detector.feature(:installer).with_scenarios?
        if (package = package_name) && !package_manager.installed?(package)
          raise ForemanMaintain::Error::Fail,
                "Error: Important rpm package #{package} is not installed!"\
                "\nInstall #{package} rpm to ensure system consistency."
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
