module Procedures::Repositories
  class Setup < ForemanMaintain::Procedure
    metadata do
      description "Setup repositories"
      confine do
        feature(:downstream) || feature(:upstream)
      end
      param :version, :required => true
    end

    def run
      with_spinner("Configuring repositories for #{@version}") do
        (feature(:downstream) || feature(:upstream)).set_repositories(@version)
      end
    end
  end
end
