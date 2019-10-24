module Procedures::Repositories
  class Setup < ForemanMaintain::Procedure
    metadata do
      description 'Setup repositories'
      preparation_steps do
        Procedures::Packages::Install.new(:packages => [ForemanMaintain::Utils::Facter.package])
      end

      confine do
        feature(:instance).downstream || feature(:upstream)
      end
      param :version,
            'Version for which repositories needs to be setup',
            :required => true
      run_once
    end

    def run
      with_spinner("Configuring repositories for #{@version}") do
        (feature(:instance).downstream || feature(:upstream)).setup_repositories(@version)
      end
    end
  end
end
