module Procedures::Repositories
  class Enable < ForemanMaintain::Procedure
    metadata do
      param :repos, 'Array of repositories to enable'
      param :use_rhsm, 'Use RHSM to enable repository',
        :flag => true, :default => false
      description 'Enable repositories'
    end
    def run
      with_spinner('Enabling repositories') do
        if @use_rhsm
          repository_manager.rhsm_enable_repos(@repos)
        else
          repository_manager.enable_repos(@repos)
        end
      end
    end
  end
end
