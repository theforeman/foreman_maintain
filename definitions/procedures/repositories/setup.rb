module Procedures::Repositories
  class Setup < ForemanMaintain::Procedure
    metadata do
      description 'Setup repositories'
      confine do
        feature(:instance).downstream || feature(:instance).upstream_install
      end
      param :version,
        'Version for which repositories needs to be setup',
        :required => true
      run_once
    end

    def run
      with_spinner("Configuring repositories for #{@version}") do
        (feature(:instance).downstream || \
         feature(:instance).upstream_install).setup_repositories(@version)
      end
    end
  end
end
