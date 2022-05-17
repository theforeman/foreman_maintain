module Procedures::Repositories
  class Disable < ForemanMaintain::Procedure
    metadata do
      param :repos, 'Array of repositories to disable'
      param :use_rhsm, 'Use RHSM to disable repository',
            :flag => true, :default => false
      description 'Disable repositories'
    end

    def run
      with_spinner('Disabling repositories') do
        if @use_rhsm
          repository_manager.rhsm_disable_repos(@repos)
        else
          repository_manager.disable_repos(@repos)
        end
      end
    end
  end
end
