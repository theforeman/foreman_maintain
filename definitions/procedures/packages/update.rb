module Procedures::Packages
  class Update < ForemanMaintain::Procedure
    metadata do
      param :packages, 'List of packages to update', :array => true
      param :assumeyes, 'Do not ask for confirmation'
      param :force, 'Do not skip if package is installed', :flag => true, :default => false
      param :warn_on_errors, 'Do not interrupt scenario on failure',
        :flag => true, :default => false
      param :yum_options, 'Extra yum options if any', :array => true, :default => []
    end

    def run
      assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes
      package_manager.clean_cache(:assumeyes => assumeyes_val)
      opts = { :assumeyes => assumeyes_val, :yum_options => @yum_options }
      packages_action(:update, @packages, opts)
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

    def description
      if @yum_options.include?('--downloadonly')
        "Download package(s) #{@packages.join(', ')}"
      else
        "Update package(s) #{@packages.join(', ')}"
      end
    end
  end
end
