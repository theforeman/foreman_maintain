module ForemanMaintain::Scenarios
  module Packages
    def self.skip_installer_run?(packages_list)
      if packages_list.is_a?(String)
        packages_list = packages_list.split(',').map(&:strip)
      end
      packages_list ||= []

      return false unless packages_list.any? { |p| p.include?('foreman_maintain') }
      return true if packages_list.length == 1

      fm_pkg = ForemanMaintain.main_package_name
      puts "ERROR: install or update '#{fm_pkg}' package individually."
      exit 1
    end

    class Status < ForemanMaintain::Scenario
      metadata do
        label :packages_status
        description 'detection of status of package version locking'
        manual_detection
      end

      def compose
        add_step(Procedures::Packages::LockingStatus)
      end
    end

    class Unlock < ForemanMaintain::Scenario
      metadata do
        label :packages_unlock
        description 'unlocking of package versions'
        manual_detection
      end

      def compose
        add_step(Procedures::Packages::UnlockVersions)
      end
    end

    class Lock < ForemanMaintain::Scenario
      metadata do
        label :packages_lock
        description 'locking of package versions'
        manual_detection
      end

      def compose
        add_step(Procedures::Packages::LockVersions)
      end
    end

    class Install < ForemanMaintain::Scenario
      metadata do
        description 'install packages in unlocked session'
        param :packages, 'List of packages to install', :array => true
        param :assumeyes, 'Do not ask for confirmation'
        manual_detection
      end

      def compose
        if Packages.skip_installer_run?(context.get(:packages))
          add_step_with_context(Procedures::Packages::Install,
                                :force => true, :warn_on_errors => true)
        else
          add_step_with_context(Procedures::Packages::InstallerConfirmation)
          add_step_with_context(Procedures::Packages::UnlockVersions)
          add_step_with_context(Procedures::Packages::Install,
                                :force => true, :warn_on_errors => true)
          add_step_with_context(Procedures::Installer::Upgrade)
          add_step(Procedures::Packages::LockingStatus)
        end
      end

      def set_context_mapping
        context.map(:packages,
                    Procedures::Packages::Install => :packages)
        context.map(:assumeyes,
                    Procedures::Packages::Install => :assumeyes)
      end
    end

    class Update < ForemanMaintain::Scenario
      metadata do
        description 'update packages in unlocked session'
        param :packages, 'List of packages to Update', :array => true
        param :assumeyes, 'Do not ask for confirmation'
        manual_detection
      end

      def compose
        if Packages.skip_installer_run?(context.get(:packages))
          add_step_with_context(Procedures::Packages::Update,
                                :force => true, :warn_on_errors => true)
        else
          add_steps_with_context(
            Procedures::Packages::UpdateAllConfirmation,
            Procedures::Packages::InstallerConfirmation,
            Procedures::Packages::UnlockVersions
          )
          add_step_with_context(Procedures::Packages::Update,
                                :force => true, :warn_on_errors => true)
          add_step_with_context(Procedures::Installer::Upgrade)
          add_step(Procedures::Packages::LockingStatus)
        end
      end

      def set_context_mapping
        context.map(:packages,
                    Procedures::Packages::Update => :packages,
                    Procedures::Packages::UpdateAllConfirmation => :packages)
        context.map(:assumeyes,
                    Procedures::Packages::Update => :assumeyes)
      end
    end
  end
end
