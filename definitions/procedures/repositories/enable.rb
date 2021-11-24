module Procedures::Repositories
  class Enable < ForemanMaintain::Procedure
    metadata do
      param :repos, 'List of repositories to enable'
      description 'Enable repositories'
    end
    def run
      with_spinner('Enabling repositories') do
        repository_manager.enable_repos(@repos)
      end
    end
  end
end
