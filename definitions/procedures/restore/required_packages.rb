module Procedures::Restore
  class RequiredPackages < ForemanMaintain::Procedure
    metadata do
      description 'Ensure required packages are installed before restore'

      param :backup_dir,
        'Path to backup directory',
        :required => true
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)
      required_packages = []
      required_packages << 'puppetserver' if backup.with_puppetserver?
      if required_packages.any?
        with_spinner('Installing required packages') do
          ForemanMaintain.package_manager.install(required_packages, assumeyes: true)
        end
      end
    end
  end
end
