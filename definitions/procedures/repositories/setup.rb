module Procedures::Repositories
  class Setup < ForemanMaintain::Procedure
    metadata do
      description 'Setup repositories'
      confine do
        feature(:downstream) || feature(:upstream)
      end
      param :version,
            'Version for which repositories needs to be setup',
            :required => true
      run_once
    end

    def run
      with_spinner("Configuring repositories for #{@version}") do
        (feature(:downstream) || feature(:upstream)).setup_repositories(@version)
      end
    end
  end
end
