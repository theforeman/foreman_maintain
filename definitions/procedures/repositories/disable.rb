module Procedures::Repositories
  class Disable < ForemanMaintain::Procedure
    metadata do
      param :repos, 'List of repositories to disable'
      description 'Disable repositories'
    end
    def run
      with_spinner('Disabling repositories') do
        feature(:system_repos).disable_repos(@repos)
      end
    end
  end
end
