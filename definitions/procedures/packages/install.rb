module Procedures::Packages
  class Install < ForemanMaintain::Procedure
    metadata do
      description 'Install packages'
      param :packages, 'List of packages to install', :array => true
      param :assumeyes, 'Do not ask for confirmation'
      param :force, 'Do not skip if package is installed', :flag => true, :default => false
      param :warn_on_errors, 'Do not interrupt scenario on failure',
            :flag => true, :default => false
    end

    def run
      assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes
      packages_action(:install, @packages, :assumeyes => assumeyes_val)
    rescue ForemanMaintain::Error::ExecutionError => e
      if @warn_on_errors
        set_status(:warning, e.message)
      else
        raise
      end
    end

    def necessary?
      @force || @packages.any? { |package| package_version(package).nil? }
    end

    def runtime_message
      "Install package(s) #{@packages.join(', ')}"
    end
  end
end
