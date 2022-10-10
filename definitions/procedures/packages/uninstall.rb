module Procedures::Packages
  class Uninstall < ForemanMaintain::Procedure
    metadata do
      description 'Uninstall packages'
      param :packages, 'List of packages to uninstall', :array => true
      param :assumeyes, 'Do not ask for confirmation'
      param :warn_on_errors, 'Do not interrupt scenario on failure',
        :flag => true, :default => false
    end

    def run
      assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes
      packages_action(:remove, @packages, :assumeyes => assumeyes_val)
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
      "Uninstalling package(s) #{@packages.join(', ')}"
    end
  end
end
