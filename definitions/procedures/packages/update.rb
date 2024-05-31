module Procedures::Packages
  class Update < ForemanMaintain::Procedure
    metadata do
      param :packages, 'List of packages to update', :array => true
      param :assumeyes, 'Do not ask for confirmation'
      param :force, 'Do not skip if package is installed', :flag => true, :default => false
      param :warn_on_errors, 'Do not interrupt scenario on failure',
        :flag => true, :default => false
      param :download_only, 'Download and cache packages only', :flag => true, :default => false
      param :clean_cache, 'If true will cause a DNF cache clean', :flag => true, :default => true
      param :enabled_repos, 'List of repositories to enable', :array => true
    end

    def run
      assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes
      package_manager.clean_cache(:assumeyes => assumeyes_val) if @clean_cache
      opts = {
        :assumeyes => assumeyes_val,
        :download_only => @download_only,
        :enabled_repos => @enabled_repos,
      }
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
      if @download_only
        "Download package(s) #{@packages.join(', ')}"
      else
        "Update package(s) #{@packages.join(', ')}"
      end
    end
  end
end
